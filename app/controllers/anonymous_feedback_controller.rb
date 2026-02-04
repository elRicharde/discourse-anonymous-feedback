# frozen_string_literal: true

class ::AnonymousFeedbackController < ::ApplicationController
  requires_plugin "discourse-anonymous-feedback"

  skip_before_action :check_xhr, only: %i[index unlock create], raise: false
  skip_before_action :preload_json, only: %i[index unlock create], raise: false
  skip_before_action :redirect_to_login_if_required, only: %i[index unlock create], raise: false
  skip_before_action :verify_authenticity_token, only: %i[unlock create], raise: false

  DOORCODE_MIN_INTERVAL = 2 # seconds
  DOORCODE_FAIL_BLOCKS = [
    [20, 86_400], # 1 day
    [15, 3_600],  # 1 hour
    [10, 600],    # 10 min
    [5, 60]       # 1 min
  ].freeze

  def index
    render :index, layout: false
  end

  def unlock
    return render json: { success: true }, status: 200 if params[:website].present? # Honeypot

    ip = request.remote_ip.to_s
    key = "anon_feedback:doorcode:#{ip}"
    now = Time.now.to_i

    blocked_until = Discourse.redis.hget(key, "blocked_until").to_i
    if blocked_until > now
      wait_s = blocked_until - now
      return render json: { error: I18n.t("anonymous_feedback.errors.rate_limited", seconds: wait_s) }, status: 429
    end

    last_attempt = Discourse.redis.hget(key, "last_attempt").to_i
    if last_attempt > 0 && (now - last_attempt) < DOORCODE_MIN_INTERVAL
      wait_s = DOORCODE_MIN_INTERVAL - (now - last_attempt)
      return render json: { error: I18n.t("anonymous_feedback.errors.rate_limited", seconds: wait_s) }, status: 429
    end

    Discourse.redis.hset(key, "last_attempt", now)
    Discourse.redis.expire(key, 86_400) # state max 1 day halten

    door_code = params[:door_code].to_s
    expected  = SiteSetting.anonymous_feedback_door_code.to_s

    ok = expected.present? &&
      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(door_code),
        ::Digest::SHA256.hexdigest(expected)
      )

    if ok
      # Reset on success
      Discourse.redis.del(key)
      session[:anon_feedback_unlocked] = true
      return render json: { success: true }, status: 200
    end

    # Failure path: count + block thresholds
    fails = Discourse.redis.hincrby(key, "fail_count", 1)

    block_seconds = DOORCODE_FAIL_BLOCKS.find { |threshold, _| fails >= threshold }&.last
    if block_seconds
      Discourse.redis.hset(key, "blocked_until", now + block_seconds)
    end

    render json: { error: I18n.t("anonymous_feedback.errors.invalid_code") }, status: 403
  end

  def create
    return render json: { success: true }, status: 200 if params[:website].present? # Honeypot

    unless session[:anon_feedback_unlocked]
      return render json: { error: I18n.t("anonymous_feedback.errors.invalid_code") }, status: 403
    end

    subject = params[:subject].to_s.strip
    message = params[:message].to_s

    unless subject.present? && message.present?
      return render json: { error: I18n.t("anonymous_feedback.errors.missing_fields") }, status: 400
    end

    max_len = SiteSetting.anonymous_feedback_max_message_length.to_i
    if max_len > 0 && message.length > max_len
      return render json: { error: I18n.t("anonymous_feedback.errors.too_long") }, status: 400
    end

    group_name = SiteSetting.anonymous_feedback_target_group.to_s.strip
    if group_name.blank?
      return render json: { error: "Target group not configured" }, status: 500
    end

    PostCreator.create!(
      Discourse.system_user,
      title: subject,
      raw: message,
      archetype: Archetype.private_message,
      target_group_names: [group_name]
    )

    session.delete(:anon_feedback_unlocked)
    render json: { success: true }, status: 200
  end
end

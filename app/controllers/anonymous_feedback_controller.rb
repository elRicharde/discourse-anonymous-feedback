# frozen_string_literal: true

class ::AnonymousFeedbackController < ::ApplicationController
  requires_plugin "discourse-anonymous-feedback"

  skip_before_action :check_xhr, only: %i[index unlock create], raise: false
  skip_before_action :preload_json, only: %i[index unlock create], raise: false
  skip_before_action :redirect_to_login_if_required, only: %i[index unlock create], raise: false
  skip_before_action :verify_authenticity_token, only: %i[unlock create], raise: false

  def index
    # zeigt entweder Code-Screen oder Formular (wenn "freigeschaltet")
    render :index, layout: false
  end

  # Türcode prüfen + "freischalten" (Session-Flag)
  def unlock
    return render json: { success: true }, status: 200 if params[:website].present? # Honeypot

    door_code = params[:door_code].to_s
    expected  = SiteSetting.anonymous_feedback_door_code.to_s

    ok = expected.present? &&
         ActiveSupport::SecurityUtils.secure_compare(
           ::Digest::SHA256.hexdigest(door_code),
           ::Digest::SHA256.hexdigest(expected)
         )

    unless ok
      return render json: { error: I18n.t("anonymous_feedback.errors.invalid_code") }, status: 403
    end

    session[:anon_feedback_unlocked] = true
    render json: { success: true }, status: 200
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

    # optional: nach erfolgreichem Senden wieder "sperren"
    session.delete(:anon_feedback_unlocked)

    render json: { success: true }, status: 200
  end
end

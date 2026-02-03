# frozen_string_literal: true

class ::AnonymousFeedbackController < ::ApplicationController
  requires_plugin "discourse-anonymous-feedback"

  skip_before_action :check_xhr, only: [:index, :create], raise: false
  skip_before_action :preload_json, only: [:index, :create], raise: false
  skip_before_action :redirect_to_login_if_required, only: [:index, :create], raise: false
  skip_before_action :verify_authenticity_token, only: [:create], raise: false

  def index
    begin
      html = render_to_string(:index, layout: false)
      render html: html.html_safe
    rescue => e
      Rails.logger.error("[anon-feedback] index error: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render plain: "anon-feedback error: #{e.class}: #{e.message}", status: 500
    end
  end

  def create
    # Honeypot
    return render json: { success: true }, status: 200 if params[:website].present?

    door_code = params[:door_code].to_s
    subject   = params[:subject].to_s.strip
    message   = params[:message].to_s

    unless door_code.present? && subject.present? && message.present?
      return render json: { error: I18n.t("anonymous_feedback.errors.missing_fields") }, status: 400
    end

    # Doorcode-Check kommt in Chapter 4
    render json: { success: true }, status: 200
  end
end

# frozen_string_literal: true

class ::AnonymousFeedbackController < ::ApplicationController
  requires_plugin ::AnonymousFeedback::PLUGIN_NAME

  skip_before_action :check_xhr, only: [:index, :create], raise: false
  skip_before_action :preload_json, only: [:index, :create], raise: false
  skip_before_action :redirect_to_login_if_required, only: [:index, :create], raise: false
  skip_before_action :verify_authenticity_token, only: [:create], raise: false

  def index
    render :index, layout: false
  end

  def create
    # Honeypot: wenn gesetzt -> Bot -> tun als ob ok
    return redirect_to "/anonymous-feedback?sent=1" if params[:website].present?

    door_code = params[:door_code].to_s
    subject   = params[:subject].to_s.strip
    message   = params[:message].to_s

    unless door_code.present? && subject.present? && message.present?
      return render plain: "Fehlende Felder", status: 400
    end

    group_name = SiteSetting.anonymous_feedback_target_group.to_s.strip
    if group_name.blank?
      return render plain: "Target group not configured", status: 500
    end

    PostCreator.create!(
      Discourse.system_user,
      title: subject,
      raw: message,
      archetype: Archetype.private_message,
      target_group_names: [group_name]
    )

    redirect_to "/anonymous-feedback?sent=1"
  end
end

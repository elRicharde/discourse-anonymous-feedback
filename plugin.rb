# frozen_string_literal: true

# name: discourse-anonymous-feedback
# about: Public doorcode form that sends PM to a group (3 endpoints: anonymous-feedback, white-board, afva)
# version: 2.0
# authors: Richard

# No enabled_site_setting: a plugin has only one, and each page has its own
# *_enabled toggle (checked in the controller via KINDS).

register_asset "stylesheets/common/anonymous-feedback.scss"

after_initialize do
  module ::AnonymousFeedback
    PLUGIN_NAME = "discourse-anonymous-feedback"
  end

  # Controller
  require_dependency File.expand_path("../app/controllers/anonymous_feedback_controller.rb", __FILE__)

  # Routes (addresses are intentionally NOT configurable, see KINDS)
  Discourse::Application.routes.append do
    ::AnonymousFeedbackController::KINDS.each_value do |cfg|
      get  cfg[:path]              => "anonymous_feedback#show"
      post "#{cfg[:path]}/unlock" => "anonymous_feedback#unlock"
      post cfg[:path]              => "anonymous_feedback#create"
    end
  end

  # Ensure plugin views are discoverable (safe even if you later drop ERB view)
  view_path = File.expand_path("../app/views", __FILE__)
  ActiveSupport.on_load(:action_controller) do
    if defined?(::AnonymousFeedbackController)
      ::AnonymousFeedbackController.prepend_view_path(view_path)
    end
  end
end
# name: discourse-anonymous-feedback
# about: Anonymous feedback form (door code) that sends PM to a group
# version: 0.3
# authors: Richard

enabled_site_setting :anonymous_feedback_enabled

after_initialize do
  module ::AnonymousFeedback
    PLUGIN_NAME = "discourse-anonymous-feedback"
  end

  # Load controller
  require_dependency File.expand_path("../app/controllers/anonymous_feedback_controller.rb", __FILE__)

  # Routes
Discourse::Application.routes.append do
  # Shell: Ember booten, muss HTML liefern
  get "/anonymous-feedback" => "anonymous_feedback#show"

  # JSON API
  post "/anonymous-feedback/unlock" => "anonymous_feedback#unlock", defaults: { format: :json }
  post "/anonymous-feedback"        => "anonymous_feedback#create", defaults: { format: :json }
end



  # Ensure Rails can find plugin views for this controller
  # (needed in some Discourse/Rails setups when using custom controllers)
  view_path = File.expand_path("../app/views", __FILE__)
  ActiveSupport.on_load(:action_controller) do
    if defined?(::AnonymousFeedbackController)
      ::AnonymousFeedbackController.prepend_view_path(view_path)
    end
  end
end

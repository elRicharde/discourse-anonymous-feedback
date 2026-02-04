# frozen_string_literal: true

# name: discourse-anonymous-feedback
# about: Anonymous feedback form (door code) that sends PM to a group
# version: 0.4
# authors: Richard

enabled_site_setting :anonymous_feedback_enabled

after_initialize do
  module ::AnonymousFeedback
    PLUGIN_NAME = "discourse-anonymous-feedback"
  end

  require_dependency File.expand_path("../app/controllers/anonymous_feedback_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    get  "/anonymous-feedback"        => "anonymous_feedback#show"
    post "/anonymous-feedback/unlock" => "anonymous_feedback#unlock", defaults: { format: :json }
    post "/anonymous-feedback"        => "anonymous_feedback#create", defaults: { format: :json }
  end
end

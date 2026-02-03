# name: discourse-anonymous-feedback
# about: Anonymous feedback form (door code) that sends PM to a group
# version: 0.2
# authors: Richard

enabled_site_setting :anonymous_feedback_enabled

after_initialize do
  module ::AnonymousFeedback
    PLUGIN_NAME = "discourse-anonymous-feedback"
  end

  require_dependency File.expand_path("../app/controllers/anonymous_feedback_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    get  "/anonymous-feedback" => "anonymous_feedback#index"
    post "/anonymous-feedback" => "anonymous_feedback#create"
  end
end

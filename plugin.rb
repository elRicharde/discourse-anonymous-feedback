# name: discourse-anonymous-feedback
# about: Anonymous feedback form (door code) that sends PM to a group
# version: 0.2
# authors: Richard

enabled_site_setting :anonymous_feedback_enabled

after_initialize do
  require_dependency File.expand_path("../app/controllers/anonymous_feedback_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    get "/anonymous-feedback" => "anonymous_feedback#index"
  end

  # Allow this endpoint even when SiteSetting.login_required = true
  if defined?(::Auth::DefaultCurrentUserProvider)
    ::Auth::DefaultCurrentUserProvider.public_routes << "anonymous_feedback#index"
  end
end


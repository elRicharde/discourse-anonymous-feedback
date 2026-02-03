# name: discourse-anonymous-feedback
# about: Anonymous feedback form (door code) that sends PM to a group
# version: 0.2
# authors: Richard

enabled_site_setting :anonymous_feedback_enabled

after_initialize do
  # Controller-Definition innerhalb des after_initialize Blocks
  class ::AnonymousFeedbackController < ::ApplicationController
    skip_before_action :check_xhr, only: [:index, :create]
    skip_before_action :preload_json, only: [:index, :create]
    skip_before_action :redirect_to_login_if_required, only: [:index, :create]
    skip_before_action :verify_authenticity_token, only: [:create]
    
    def index
      # Zeige das Formular
      render json: { success: true }
    end
    
    def create
      # Verarbeite das Feedback
      door_code = params[:door_code]
      message = params[:message]
      
      # Hier kannst du den Code zur Verarbeitung einfügen
      # z.B. PM an eine Gruppe senden
      
      render json: { success: true }
    end
  end
  
  # Routes registrieren
  Discourse::Application.routes.append do
    get "/anonymous-feedback" => "anonymous_feedback#index"
    post "/anonymous-feedback" => "anonymous_feedback#create"
  end
end

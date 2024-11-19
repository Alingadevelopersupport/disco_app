module DiscoApp::Concerns::UserAuthenticatedController

  extend ActiveSupport::Concern
  include ShopifyApp::LoginProtection

  included do
    before_action :shopify_user
  end

  private

    def shopify_user
      Rails.logger.info "::::::: UserAuthenticatedController shopify_user ::::::: #{session[:shopify_user].inspect} ::::::: #{DiscoApp::User.find(session[:shopify_user])&.inspect} :::::::"
      @user = DiscoApp::User.find(session[:shopify_user])
    rescue ActiveRecord::RecordNotFound
      redirect_to disco_app.new_user_session_path
    end

end

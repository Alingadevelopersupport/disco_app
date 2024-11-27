class DiscoApp::UserSessionsController < ApplicationController

  include DiscoApp::Concerns::AuthenticatedController

  def new
    Rails.logger.info "sanitized_shop_name ::::::: #{sanitized_shop_name.present?}"
    authenticate if sanitized_shop_name.present?
  end

  def create
    authenticate
  end

  def callback
    Rails.logger.info "::::::: call callback :::::::"
    if auth_hash
      Rails.logger.info "::::::: call if of callback :::::::"
      login_user
      redirect_to return_address
    else
      Rails.logger.info "::::::: call else of callback :::::::"
      redirect_to root_path
    end
  end

  def destroy
    session[:shopify_user] = nil
    redirect_to root_path
  end

  protected

    def auth_hash
      request.env['omniauth.auth']
    end

    def associated_user(auth_hash)
      auth_hash['extra']['associated_user']
    end

    def authenticate
      if sanitized_shop_name.present?
        url = "#{main_app.root_path}auth/shopify_user?shop=#{sanitized_shop_name}"
        Rails.logger.info "call auth shopify user ::::::: #{sanitized_shop_name} ::::::: #{url} :::::::"
        fullpage_redirect_to "#{main_app.root_path}auth/shopify_user?shop=#{sanitized_shop_name}"
      else
        Rails.logger.info "::::::: call return address :::::::"
        redirect_to return_address
      end
    end

    def login_user
      @user = DiscoApp::User.create_user(associated_user(auth_hash), @shop)
      session[:shopify_user] = @user.id
    end

    def return_address
      Rails.logger.info "session ::::::: #{session}"
      Rails.logger.info "main_app root_url ::::::: #{main_app&.root_url}"
      session.delete(:return_to) || main_app.root_url
    end

    def sanitized_shop_name
      # Rails.logger.info "shop ::::::: #{@shop.inspect}"
      @shop.present? ? @shop.shopify_domain : super
    end

end

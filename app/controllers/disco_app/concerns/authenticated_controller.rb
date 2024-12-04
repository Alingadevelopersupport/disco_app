module DiscoApp::Concerns::AuthenticatedController

  extend ActiveSupport::Concern
  include ShopifyApp::LoginProtection

  included do
    before_action :auto_login
    before_action :check_shop_whitelist
    before_action :login_again_if_different_user_or_shop
    before_action :shopify_shop
    before_action :check_installed
    before_action :check_current_subscription
    before_action :check_active_charge
    around_action :activate_shopify_session
    layout 'embedded_app'
  end

  private

    def auto_login
      Rails.logger.info "::::::: RAILS_ENV ::::::: #{ENV['RAILS_ENV']} :::::::"
      Rails.logger.info "::::::: auto_login ::::::: #{shop_session.inspect} ::::::: request_hmac_valid ::::::: #{request_hmac_valid?} ::::::: #{shop_session.nil? && request_hmac_valid?} :::::::"
      
      # Log when we are skipping auto_login because the session already exists
      if shop_session
        Rails.logger.info "Shop session already exists, skipping auto_login."
        return
      end

      # Proceed with auto-login logic if no session exists
      shop = DiscoApp::Shop.find_by(shopify_domain: sanitized_shop_name)
      Rails.logger.info "::::::: auto_login shop lookup::::::: #{shop.inspect} :::::::"
      
      if shop.blank?
        Rails.logger.warn "No shop found for domain: #{sanitized_shop_name}"
        return
      end

      session[:shop_id] = shop.id
      session[:shopify_domain] = sanitized_shop_name
      Rails.logger.info "Shop session created for domain: #{sanitized_shop_name} with shop_id: #{shop.id}"
    end

    def shopify_shop
      if shop_session
        @shop = DiscoApp::Shop.find_by!(shopify_domain: @current_shopify_session.domain)
        Rails.logger.info "Shop found for domain #{@current_shopify_session.domain}: #{@shop.inspect}"
      else
        Rails.logger.warn "No shop session found, redirecting to login."
        redirect_to_login
      end
    end

    def check_installed
      if @shop.awaiting_install? || @shop.installing?
        redirect_if_not_current_path disco_app.installing_path
        return
      end

      if @shop.awaiting_uninstall? || @shop.uninstalling?
        redirect_if_not_current_path disco_app.uninstalling_path
        return
      end

      if !@shop.installed?
        Rails.logger.info "Shop is not installed, redirecting to install path."
        redirect_if_not_current_path disco_app.install_path
      end
    end

    def check_current_subscription
      if !@shop.current_subscription?
        Rails.logger.info "Shop does not have a current subscription, redirecting to new subscription path."
        redirect_if_not_current_path disco_app.new_subscription_path
      end
    end

    def check_active_charge
      Rails.logger.info "::::::: 1 :::::::"
      return unless @shop.current_subscription?
      Rails.logger.info "::::::: 2 :::::::"
      return unless @shop.current_subscription.requires_active_charge?
      Rails.logger.info "::::::: 3 :::::::"
      return if @shop.development?
      Rails.logger.info "::::::: 4 :::::::"
      return if @shop.current_subscription.active_charge?
      Rails.logger.info "::::::: 5 :::::::"
      Rails.logger.info "No active charge found for subscription, redirecting to new subscription charge path."
      redirect_if_not_current_path disco_app.new_subscription_charge_path(@shop.current_subscription)
    end

    def redirect_if_not_current_path(target)
      Rails.logger.info "::::::: target ::::::: #{target} ::::::: request.path ::::::: #{request.path} :::::::"
      if request.path != target
        Rails.logger.info "Redirecting to #{target} because the current path (#{request.path}) is different."
        redirect_to target
      end
    end

    def request_hmac_valid?
      Rails.logger.info "::::::: request::::::: #{request.query_string} :::::::"
      validate_hmac = DiscoApp::RequestValidationService.hmac_valid?(request.query_string, ShopifyApp.configuration.secret)
      Rails.logger.info "::::::: validate_hmac ::::::: #{validate_hmac} :::::::"
      validate_hmac
    end

    def check_shop_whitelist
      return unless shop_session
      return if ENV['WHITELISTED_DOMAINS'].blank?

      whitelist = ENV['WHITELISTED_DOMAINS']&.split(',')
      if whitelist.include?(shop_session.url)
        Rails.logger.info "Shop domain #{shop_session.url} is whitelisted."
      else
        Rails.logger.warn "Shop domain #{shop_session.url} is not whitelisted. Redirecting to login."
        redirect_to_login
      end
    end
end

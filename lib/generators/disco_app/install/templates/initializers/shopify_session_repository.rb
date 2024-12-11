if Rails.configuration.cache_classes
  ShopifyApp::SessionRepository.shop_storage = DiscoApp::SessionStorage
else
  reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
  reloader.to_prepare do
    ShopifyApp::SessionRepository.shop_storage = DiscoApp::SessionStorage
  end
end

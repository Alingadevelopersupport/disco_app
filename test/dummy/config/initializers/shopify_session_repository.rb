if Rails.configuration.cache_classes
  ShopifyApp::SessionRepository.shop_storage = DiscoApp::SessionStorage
else
  ActiveSupport::Reloader.to_prepare do
    ShopifyApp::SessionRepository.shop_storage = DiscoApp::SessionStorage
  end
end

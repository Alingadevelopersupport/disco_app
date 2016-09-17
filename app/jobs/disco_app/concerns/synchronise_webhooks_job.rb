module DiscoApp::Concerns::SynchroniseWebhooksJob
  extend ActiveSupport::Concern

  # Ensure the webhooks registered with our shop are the same as those listed
  # in our application configuration.
  def perform(shop)
    # Get the full list of expected webhook topics.
    expected_topics = [:'app/uninstalled', :'shop/update'] + (DiscoApp.configuration.webhook_topics || [])

    # Registered any webhooks that haven't been registered yet.
    (expected_topics - current_topics).each do |topic|
      ShopifyAPI::Webhook.create(
        topic: topic,
        address: webhooks_url,
        format: 'json'
      )
    end

    # Remove any extraneous topics.
    current_webhooks.each do |webhook|
      unless expected_topics.include?(webhook.topic.to_sym)
        ShopifyAPI::Webhook.delete(webhook.id)
      end
    end

    # Ensure webhook addresses are current.
    current_webhooks.each do |webhook|
      unless webhook.address == webhooks_url
        webhook.address = webhooks_url
        webhook.save
      end
    end
  end

  private

    # Return a list of currently registered topics.
    def current_topics
      current_webhooks.map(&:topic).map(&:to_sym)
    end

    # Return a list of current registered webhooks.
    def current_webhooks
      @current_webhooks ||= ShopifyAPI::Webhook.find(:all)
    end

    # Return the absolute URL to the webhooks endpoint.
    def webhooks_url
      DiscoApp::Engine.routes.url_helpers.webhooks_url
    end

end

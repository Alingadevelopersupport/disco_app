require 'test_helper'

class DiscoApp::SynchroniseWebhooksJobTest < ActionController::TestCase
  include ActiveJob::TestHelper

  def setup
    @shop = disco_app_shops(:widget_store)

    stub_request(:get, "#{@shop.admin_url}/webhooks.json").to_return(status: 200, body: api_fixture('widget_store/webhooks').to_json)
    stub_request(:post, "#{@shop.admin_url}/webhooks.json").to_return(status: 200)
  end

  def teardown
    @shop = nil

    WebMock.reset!
  end

  test 'webhook synchronisation job creates webhooks for all expected topics' do
    perform_enqueued_jobs do
      DiscoApp::SynchroniseWebhooksJob.perform_later(@shop)
    end

    # Assert that all 4 expected webhook topics were POSTed to.
    ['app/uninstalled', 'shop/update', 'orders/create', 'orders/paid'].each do |expected_webhook_topic|
      assert_requested(:post, "#{@shop.admin_url}/webhooks.json", times: 1) { |request| request.body.include?(expected_webhook_topic) }
    end
  end

end
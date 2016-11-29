ENV['RAILS_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require './test_app/dummy/config/environment'
require 'solidus_benchmark'
require 'ffaker'
require 'spree/testing_support/factories'

SolidusBenchmark.new "core/refresh_rates" do
  setup do
    FactoryGirl.create(:order_with_line_items)
  end

  measure do
    Spree::Shipment.last.refresh_rates
  end
end

[1, 10].each do |item_count|
  SolidusBenchmark.new "core/order/update/checkout_with_#{item_count}" do
    setup do
      FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    end

    measure do
      Spree::Order.first.update!
    end
  end
end

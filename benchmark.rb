ENV['RAILS_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require './test_app/dummy/config/environment'
require 'solidus_benchmark'
require 'ffaker'
require 'spree/testing_support/factories'

SolidusBenchmark.new "core/refresh_rates" do
  description %q{This benchmark measures the speed of `ShippingMethod#refresh_rates`, which estimates and creates shipping rates for a shipment.}
  note "As of Solidus 1.3, taxes are calculated as part of shipping rate estimation"

  setup do
    FactoryGirl.create(:order_with_line_items)
  end

  measure do
    Spree::Shipment.last.refresh_rates
  end
end

[1, 2, 5].each do |item_count|
  SolidusBenchmark.new "core/order/cart/update/cold_update_with_#{item_count}_items" do
    description %Q{This benchmark measures the speed of `Order#update!` for an order with #{item_count} items. This test reloads the order from memory before each update.}
    note "As of Solidus 2.1, taxes are calculated as part of every order.update!"

    setup do
      FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    end

    measure do
      Spree::Order.first.update!
    end
  end
end

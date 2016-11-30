require 'benchmark_helper'

SolidusBenchmark.new "shipment/refresh_rates" do
  description %q{This benchmark measures the speed of `ShippingMethod#refresh_rates`, which estimates and creates shipping rates for a shipment.}
  note "As of Solidus 1.3, taxes are calculated as part of shipping rate estimation"

  setup do
    FactoryGirl.create(:order_with_line_items)
  end

  measure do
    Spree::Shipment.last.refresh_rates
  end
end

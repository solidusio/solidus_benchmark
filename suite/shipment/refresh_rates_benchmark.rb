require 'benchmark_helper'

[2, 10, 100].each do |n|
  SolidusBenchmark.new "shipment/refresh_rates/#{n}_shipping_methods" do
    description %Q{This benchmark measures the speed of `ShippingMethod#refresh_rates`, which estimates and creates shipping rates for a shipment. For this test there are #{n} shipping methods available}
    note "As of Solidus 1.3, taxes are calculated as part of shipping rate estimation"

    setup do
      FactoryGirl.create(:order_with_line_items)
      (n-1).times do
        FactoryGirl.create(:shipping_method)
      end
    end

    measure do
      Spree::Shipment.last.refresh_rates
    end
  end
end

require 'benchmark_helper'

[1, 2, 5].each do |item_count|
  SolidusBenchmark.new "order/update/cart_with_#{item_count}_items/cold" do
    description %Q{This benchmark measures the speed of `Order#update!` for an order with #{item_count} items. This test reloads the order from memory before each update.}
    note "As of Solidus 2.1, taxes are calculated as part of every order.update!"

    setup do
      FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    end

    measure do
      Spree::Order.first.update!
    end
  end

  SolidusBenchmark.new "order/update/cart_with_#{item_count}_items/hot" do
    description %Q{This benchmark measures the speed of `Order#update!` for an order with #{item_count} items. This test keeps the order in memory between updates.}
    note "As of Solidus 2.1, taxes are calculated as part of every order.update!"

    setup do
      FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    end

    before do
      @order = Spree::Order.first
      @order.update!
    end

    measure do
      @order.update!
    end
  end
end

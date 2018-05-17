require 'benchmark_helper'

SolidusBenchmark.new "order/full_checkout" do
  description %Q{A complete checkout of a simple order using only models}

  setup do
    state = FactoryGirl.create(:state)
    country = state.country
    global_zone = FactoryGirl.create(:global_zone)

    @store = FactoryGirl.create(:store)
    @variant = FactoryGirl.create(:variant).reload
    FactoryGirl.create(:shipping_method, zones: [global_zone])

    FactoryGirl.create(:tax_rate, tax_category: @variant.tax_category, zone: global_zone)

    @address_attributes = FactoryGirl.attributes_for(:ship_address, state_id: state.id, country_id: country.id)
    @payment_method = FactoryGirl.create(:credit_card_payment_method)
    @source_attributes = FactoryGirl.attributes_for(:credit_card)
  end

  before do
    Spree::Order.destroy_all
  end

  measure do
    order = Spree::Order.new(store: @store)
    order.contents.add(@variant)
    order.next!

    # Address
    order.reload
    order.attributes = {
      email: "benchmark@example.com",
      ship_address_attributes: @address_attributes,
      bill_address_attributes: @address_attributes
    }
    order.save!
    order.next!

    # Delivery
    order.reload
    order.next!

    # Payment
    order.reload
    order.payments.new(
      payment_method_id: @payment_method.id,
      source: Spree::CreditCard.new(@source_attributes)
    )
    order.save!
    order.next!

    # Confirm
    order.reload
    order.complete!

    raise "order wasn't completed" unless order.completed?
  end
end

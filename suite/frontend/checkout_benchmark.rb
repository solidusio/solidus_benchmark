require 'benchmark_helper'

SolidusBenchmark.new "frontend/checkout" do
  setup do
    @store = FactoryGirl.create(:store)
    @country = FactoryGirl.create(:country, states_required: true)
    @state = FactoryGirl.create(:state, country: @country)
    FactoryGirl.create(:stock_location)
    @product = FactoryGirl.create(:product, name: "RoR Mug")
    @variant = @product.master
    @payment_method = FactoryGirl.create(:credit_card_payment_method)
    @shipping_method = FactoryGirl.create(:shipping_method)
  end

  before do
    @session = Rack::Test::Session.new(Rails.application)
    @session.post("/orders/populate", {variant_id: @variant.id, quantity: 1})
  end

  measure do
    @session.get("/checkout/address")
    r = @session.patch("/checkout/update/address", {
      "order[email]" => "test@example.com",
      "order[bill_address_attributes][firstname]" => "DeeDee",
      "order[bill_address_attributes][lastname]" => "Ramone",
      "order[bill_address_attributes][address1]" => "53rd and 3rd",
      "order[bill_address_attributes][address2]" => "",
      "order[bill_address_attributes][city]" => "New York",
      "order[bill_address_attributes][country_id]" => @country.id,
      "order[bill_address_attributes][state_id]" => @state.id,
      "order[bill_address_attributes][zipcode]" => "10001",
      "order[bill_address_attributes][phone]" => "5555555555",
      "order[use_billing]" => "1",
    })
    raise unless r.location =~ %r{/checkout/delivery\z}

    @shipment = Spree::Shipment.last
    @session.get("/checkout/delivery")
    r = @session.patch("/checkout/update/delivery", {
      "order[shipments_attributes][0][selected_shipping_rate_id]" => @shipment.shipping_rates.last.id,
      "order[shipments_attributes][0][id]" => @shipment.id
    })

    raise unless r.location =~ %r{/checkout/payment\z}
    @session.get("/checkout/payment")
    r = @session.patch("/checkout/update/payment", {
      "order[payments_attributes][][payment_method_id]" => @payment_method.id,
      "payment_source[#{@payment_method.id}][name]" => "DeeDee Ramone",
      "payment_source[#{@payment_method.id}][number]" => "4111 1111 1111 1111",
      "payment_source[#{@payment_method.id}][expiry]" => "12 / 30",
      "payment_source[#{@payment_method.id}][verification_value]" => "123",
    })

    @session.get("/checkout/confirm")
    r = @session.patch("/checkout/update/confirm")

    raise unless r.location =~ %r{/orders/}
  end
end

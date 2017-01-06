require 'benchmark_helper'

SolidusBenchmark.new "frontend/product_show" do
  setup do
    @product = FactoryGirl.create(:product)
  end

  before do
    @session = Rack::Test::Session.new(Rails.application)
  end

  measure do
    @session.get("/products/#{@product.slug}")
  end
end

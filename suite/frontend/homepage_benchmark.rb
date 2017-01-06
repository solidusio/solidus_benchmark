require 'benchmark_helper'

SolidusBenchmark.new "frontend/homepage" do
  setup do
    10.times do
      FactoryGirl.create(:product)
    end
  end

  before do
    @session = Rack::Test::Session.new(Rails.application)
  end

  measure do
    @session.get("/")
  end
end

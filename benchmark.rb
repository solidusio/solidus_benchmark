ENV['RAILS_ENV'] = 'test'
require './dummy/config/environment'
require 'spree/testing_support/factories'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

class SolidusBenchmark
  class Stddev
    def initialize(samples)
      @samples = samples
    end

    def mean
      @mean ||= @samples.inject(:+) / @samples.length
    end

    def variance
      @samples.map do |sample|
        v = (sample - mean)
        v * v
      end.inject(:+) / @samples.length
    end

    def stddev
      @stddev ||= Math.sqrt(variance)
    end
  end

  class Run
  end

  def initialize(label, &block)
    @label = label

    instance_exec(self, &block)

    run!
  end

  def setup(&block)
    @setup = block
  end

  def test(&block)
    @test = block
  end

  def measure_once
    run = Run.new
    run.instance_exec(&@setup)

    Benchmark.realtime do
      run.instance_exec(&@test)
    end
  end

  def measure_for(timeout, samples)
    measurements = []
    while measurements.length < samples && measurements.inject(0, :+) < timeout
      measurements << measure_once
    end
    measurements
  end

  def run!
    # Warmup
    measure_once

    # Take real measurements
    measurements = measure_for(2, 10)

    p measurements

    gemspec = Gem::Specification.find_by_name("solidus")
    version = gemspec.version.to_s

    stats = Stddev.new(measurements)
    output = {
      label: @label,
      solidus_version: version,
      database: ActiveRecord::Base.connection.adapter_name,
      mean: stats.mean,
      stddev: stats.stddev
    }.to_json

    puts output
  end
end

SolidusBenchmark.new "refresh_rates" do
  setup do
    FactoryGirl.create(:order_with_line_items)
  end

  test do
    Spree::Shipment.last.refresh_rates
  end
end

[1, 10].each do |item_count|
  SolidusBenchmark.new "update incomplete order with #{item_count} items" do
    setup do
      FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    end

    test do
      Spree::Order.first.update!
    end
  end
end

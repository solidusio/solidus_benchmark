require './dummy/config/environment'
require 'spree/testing_support/factories'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

module Benchmark
  module Solidus
    def solidus(label, time: 5, warmup: 2, &block)
      report = Benchmark.ips(time, warmup, true) do |x|
        x.report(label, &block)
      end

      entry = report.entries.first

      gemspec = Gem::Specification.find_by_name("solidus")
      version = gemspec.version.to_s

      output = {
        label: label,
        version: version,
        iterations_per_second: entry.ips,
        iterations_per_second_standard_deviation: entry.stddev_percentage
      }.to_json

      puts output
    end
  end
  extend Solidus
end

DatabaseCleaner.cleaning do
  FactoryGirl.create(:order_with_line_items)
  Benchmark.solidus "refresh_rates" do
    Spree::Shipment.last.refresh_rates
  end
end

[1, 10].each do |item_count|
  DatabaseCleaner.cleaning do
    FactoryGirl.create(:order_with_line_items, line_items_count: item_count)
    Benchmark.solidus "update incomplete order with #{item_count} items" do
      Spree::Order.first.update!
    end
  end

  DatabaseCleaner.cleaning do
    FactoryGirl.create(:completed_order_with_totals, line_items_count: item_count)
    Benchmark.solidus "update completed order with #{item_count} items" do
      Spree::Order.first.update!
    end
  end
end

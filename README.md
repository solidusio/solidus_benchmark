# Solidus Benchmark

This is a suite of benchmarks testing the relative performance of different Solidus versions.

The results can be viewed at [benchmarks.solidus.io](https://benchmarks.solidus.io/)

## Running Benchmarks

To run all benchmarks against all versions of Solidus on both MySQL and PostgreSQL, simply run:

```
rake benchmark:all
```

This will save results as json files in the `data/` directory.

The suite can be run on just one version using

```
rake benchmark
```

A single file can be run using

```
ruby -Isuite suite/some_benchmark.rb
```

## Rendering website

Just run:

```
ruby render.rb
```

This will generate webpages in the `output/` directory based on the results in the `data/` directory.


## Writing benchmarks

Benchmarks are composed of three steps `setup`, `before`, and `measure`

``` ruby
SolidusBenchmark.new "order/update/cart" do
  setup do
    FactoryGirl.create(:order_with_line_items, line_items_count: 2)
  end

  before do
    @order = Spree::Order.first
    @order.update!
  end

  measure do
    @order.update!
  end
end
```

Benchmarks are run as follows:

* Run `setup` block once to pre-populate the database with some data for the test.
* Loop until sufficient data is collected:
  * Run `before` block to perform any tasks that should be run before the actual test. This may be used to clean any data from the previous run of `measure`
  * Run `measure` block. This operation is what is actually measured.
* Run DatabaseCleaner to truncate databased


## Limitations

* [benchmarks.solidus.io](https://benchmarks.solidus.io/) is generated from my work computer (i7-4790 CPU @ 3.60GHz). While not totally unreasonable, it would be better to run benchmarks on a machine more like what's generally used in production (like an EC2 instance) and with a database on a separate machine.
* The benchmarks are somewhat synthetic. Setup for each benchmark creates data relevant to the test. A real production database would have a lot more records in every table.
* The method of measurement works well for measuring relatively slow methods (more than ~50 microseconds), but would be a poor fit for micobenchmarks. Tools like the excellent benchmark-ips are more suitable for that task.

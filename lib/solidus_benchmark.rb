require 'database_cleaner'
require 'fileutils'
require 'stackprof'
require 'flamegraph'

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

  class Instance
  end

  def initialize(label, &block)
    @label = label
    @setup = @before = @measure = ->{}

    instance_exec(self, &block)

    run!
  end

  def description(desc)
    @description = desc
  end

  def note(note)
    @notes ||= []
    @notes << note
  end

  # Specify a block that will be run once to pre-populate the database
  def setup(&block)
    @setup = block
  end

  # Specify a block which will be run before each measured block.
  # This will be run multiple times, both for warmup and pre-measurement.
  def before(&block)
    @before = block
  end

  # The block of code to be measured.
  # This will be run multiple times, both for warmup and measurement.
  def measure(&block)
    @measure = block
  end

  def measure_with(&measure)
    run = @instance.dup
    run.instance_exec(&@before)

    runner = ->{ run.instance_exec(&@measure) }
    if measure.arity == 0
      measure.call(&runner)
    else
      measure.call(runner)
    end
  end

  def measure_for(timeout)
    measurements = []
    while measurements.length && measurements.inject(0, :+) < timeout
      measurements << measure_with(&Benchmark.method(:realtime))
    end
    measurements
  end

  def run!
    DatabaseCleaner.start

    @instance = Object.new
    @instance.instance_exec(&@setup)

    # Warmup
    measure_for(1)

    # Take real measurements
    measurements = measure_for(5)
    stats = Stddev.new(measurements)

    # Profile
    profile_dir = "profile/#{@label}"
    fidelity = (stats.mean * 1000.0) # fidelity value in microseconds for desired precision
    fidelity = fidelity /= 500 # we would like to see ~500 datapoints
    fidelity = [fidelity, 0.05].max # sampling seems to hang beyond this
    fidelity = [fidelity, 0.5].min # don't go slower than the default
    FileUtils.mkdir_p(profile_dir)
    measure_with do |runner|
      StackProf.run(mode: :wall, out: "#{profile_dir}/stackprof-wall.dump", interval: (fidelity * 1000).to_i, &runner)
    end
    measure_with do |runner|
      StackProf.run(mode: :cpu, out: "#{profile_dir}/stackprof-cpu.dump", interval: (fidelity * 1000).to_i, &runner)
    end
    measure_with do |runner|
      File.open("#{profile_dir}/activerecord.sql", 'w') do |f|
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = ActiveSupport::Logger.new(f)
        runner.call
        ActiveRecord::Base.logger = old_logger
      end
    end
    measure_with do |runner|
      Flamegraph.generate("#{profile_dir}/flamegraph.html", {fidelity: fidelity}, &runner)
    end

    DatabaseCleaner.clean

    gemspec = Gem::Specification.find_by_name("solidus")
    version = gemspec.version.to_s

    output = {
      label: @label,
      solidus_version: version,
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      database: ActiveRecord::Base.connection.adapter_name,
      mean: stats.mean,
      iterations: measurements.count,
      stddev: stats.stddev,
      description: @description,
      notes: @notes || []
    }.to_json

    puts output
  rescue StandardError => e
    STDERR.puts "#{e.class}: #{e.message}\n    #{e.backtrace.join("\n    ")}"
  end
end


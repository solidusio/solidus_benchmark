require 'json'
require 'active_support'

lines = Dir['./data/**/*.json'].flat_map do |filename|
  IO.readlines(filename)
end
lines.map! do |json|
  next if json == "\n"
  JSON.parse(json)
end
lines.compact!

benchmarks = lines.group_by do |data|
  data['label']
end

DATABASE_COLOURS = {
  "Mysql2" => '#e48e00',
  "SQLite" => '#d0d0d0',
  "PostgreSQL" => '#336791',
}

class BenchmarkResultHTML < Struct.new(:measurements)
  def chart_data
    {
      labels: values_for(:solidus_version),
      datasets: values_for('database').map do |database|
        {
          label: database,
          backgroundColor: DATABASE_COLOURS[database],
          data: values_for(:solidus_version).map do |version|
            get_attr(:mean, solidus_version: version, database: database) * 1000.0
          end,
          fullData: values_for(:solidus_version).map do |version|
            get_measurement(solidus_version: version, database: database)
          end
        }
      end
    }
  end

  def label
    measurements.first['label']
  end

  def values_for(key)
    measurements.map{|x| x[key.to_s] }.sort.uniq
  end

  def get_measurements(attributes)
    measurements.select do |measurement|
      attributes.all? do |key, value|
        measurement[key.to_s] == value
      end
    end
  end

  def get_measurement(attributes)
    measurements = get_measurements(attributes)
    if measurements.length > 1
      measurements.each do |m|
        p m
      end
      raise "multiple measurements for #{attributes}: #{measurements.inspect}"
    end
    measurements[0]
  end

  def get_attr(attr, attributes)
    get_measurement(attributes)[attr.to_s]
  end

  def description
    measurements[0]['description']
  end

  def notes
    measurements[0]['notes']
  end

  def description_html
    "<p>#{description}</p>"
  end

  def notes_html
    return if !notes || notes.empty?
    "<h3>Notes</h3><ul>" + notes.map do |note|
      "<li>#{note}</li>"
    end.join + "</ul>"
  end

  def html
    <<-HTML
<html>
<head>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.1.3/Chart.bundle.min.js"></script>
<title>#{label} - Solidus Benchmark</title>
<style>
body {
  max-width: 960px;
  margin: auto;
}

a {
  text-decoration: none;
}
</style>
</head>
<body>

<a href="/">« all benchmarks</a>

<h1>#{label}</h1>

#{description_html}

<canvas id="chart" width="400" height="200"></canvas>

#{notes_html}

<script>
var ctx = document.getElementById("chart");

var data = #{JSON.dump(chart_data)};

var options = {
  scales: {
    yAxes: [{
      display: true,
      ticks: {
        beginAtZero: true
      },
      scaleLabel: {
        display: true,
        labelString: "milliseconds"
      }
    }]
  },

  tooltips: {
    callbacks: {
      title: function (tooltipItem, data) {
        var measurement = data.datasets[tooltipItem[0].datasetIndex].fullData[tooltipItem[0].index];
        return ["Solidus " + measurement.solidus_version, measurement.database];
      },
      label: function (tooltipItem, data) {
        var measurement = data.datasets[tooltipItem.datasetIndex].fullData[tooltipItem.index];
        return [
          "mean: " + (measurement.mean*1000).toFixed(2) + "ms",
          "stddev: " + (measurement.stddev*1000).toFixed(2) + "ms",
          "",
          "iterations: " + measurement.iterations + " in " + (measurement.iterations * measurement.mean).toFixed(2) + "s",
          "ruby version: " + measurement.ruby_version,
          "rails version: " + measurement.rails_version,
        ]
      }
    }
  }
};

var myBarChart = new Chart(ctx, {
    type: 'bar',
    data: data,
    options: options
});

</script>

</body>
</html>
HTML
  end
end

class BenchmarkIndexHTML < Struct.new(:benchmarks)
  def listing_html
    benchmarks.map do |name, measurements|
      %{<li><a href="./#{name}.html">#{name}</a></li>}
    end
  end

  def html
    <<-HTML
<html>
<head>
<title>Solidus Benchmark</title>
<style>
body {
  max-width: 960px;
  margin: auto;
}

a {
  text-decoration: none;
}
</style>
</head>
<body>
<h1>Solidus Benchmarks</h1>
<ul>
    #{listing_html.join}
</ul>
</body>
</html>
HTML
  end
end


require 'fileutils'
FileUtils.mkdir_p('output')

benchmark = benchmarks.each do |name, measurements|
  result = BenchmarkResultHTML.new(measurements)
  filename = "output/#{name}.html"
  FileUtils.mkdir_p(File.dirname(filename))
  File.write(filename, result.html)
end

index = BenchmarkIndexHTML.new(benchmarks)
File.write("output/index.html", index.html)

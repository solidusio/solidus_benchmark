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
            get_mean(solidus_version: version, database: database)
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

  def get_mean(attributes)
    get_measurement(attributes)['mean'] * 1000
  end

  def html
    <<-HTML
<html>
<head>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.1.3/Chart.bundle.min.js"></script>
</head>
<body>

<h1>#{label}</h1>

<canvas id="chart" width="400" height="100"></canvas>

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

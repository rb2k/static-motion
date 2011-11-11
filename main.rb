require 'rubygems'
require 'bundler/setup'
require 'erb'
require 'fileutils'
require 'gpx'

input_folder = ARGV[0]
output_folder = ARGV[1]

gpx_files = Dir["#{input_folder}/*.gpx"].sort
raise "No .gpx files found in #{ARGV[0].inspect}" if gpx_files.empty?



index_template = ERB.new(IO.read("templates/index.erb"))

detail_template = ERB.new(IO.read("templates/detail.erb"))


#make sure the path is there
FileUtils.mkpath "#{output_folder}/details/"
#Delete old detail files
puts "Cleaning the details folder"
Dir["#{output_folder}/details/*.html"].each {|detail_file| File.delete(detail_file)}
Dir["#{output_folder}/details/*.gpx"].each {|detail_file| File.delete(detail_file)}
#Copy over static files
static_files = Dir.glob('static_files/*')
FileUtils.cp_r static_files, output_folder

#This is where we'll save hashes for our index page
@gpx_data = []

gpx_files.each_with_index do |gpx_file, index|
  puts "[#{index+1} / #{gpx_files.size}] Processing: #{gpx_file}"
  begin
    @parsed_gpx = GPX::GPXFile.new(:gpx_file => gpx_file)
    raise "No duration found" if @parsed_gpx.duration.to_i == 0

    @gpx_filename = File.basename(gpx_file)
    FileUtils.cp_r gpx_file, "#{output_folder}/details/"
    File.open("#{output_folder}/details/#{File.basename(gpx_file)}.html", 'w') {|f| f.write(detail_template.result) }

    @gpx_data << {
      :date => @parsed_gpx.tracks.first.points.first.time, 
      :file_name => File.basename(gpx_file),
      :distance => @parsed_gpx.distance({:units => 'meters' }).to_i,
      :duration => (@parsed_gpx.duration / 60).to_i,
      :speed_avg => @parsed_gpx.average_speed({:units => 'kilometers'}).round(2)
    }

  rescue StandardError => e
    puts "Error for file #{gpx_file}: #{e.message}"
  end
end
@gpx_data.sort_by!{|file| file[:date].to_i}.reverse!

@average_speed = (@gpx_data.map{|track| track[:speed_avg]}.inject(:+) / @gpx_data.size.to_f).round(2)
@average_distance = (@gpx_data.map{|track| track[:distance]}.inject(:+) / @gpx_data.size)
@average_duration = (@gpx_data.map{|track| track[:duration]}.inject(:+) / @gpx_data.size)


File.open("#{output_folder}/index.html", 'w') {|f| f.write(index_template.result) }

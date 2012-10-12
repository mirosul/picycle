#!/usr/bin/ruby

def radians(angle)
  (angle/180.0000000)*Math::PI
end

def arccos(x)
  Math.atan2(Math.sqrt(1.0 - x*x), x)
end

# available tracks
tracks = []
available_tracks = `ls ./tracks`
available_tracks.each_line do |track|
  tracks << track.strip
end

# user selects a track
tracks.each_with_index do |track, index|
  puts "#{index}. #{track}#{ index == 0 ? ' (default)' : ''}"
end

puts "Enter your destiny: "
selected_index = gets
selected_index = '0' if selected_index.chomp == ""
selected_track = tracks[selected_index.chomp.to_i]
csv_file = "./tracks/#{selected_track}/#{selected_track}.csv"

# reads an input file from ./tracks
require 'csv'
puts "reading track data"
track = CSV.read(csv_file) - [["Latitude", "Longitude", "Elevation"]]

# calculate the distance between the points
puts "calculating total distance"
total_distance = 0
track.each_with_index do |row, i|
  track[i][0] = track[i][0].to_f
  track[i][1] = track[i][1].to_f
  track[i][2] = track[i][2].to_f

  if i == 0
    track[i][3] = 0
    track[i][4] = 0

    next
  end

  prev_latitude = track[i-1][0]
  prev_longitude = track[i-1][1]

  latitude = track[i][0]
  longitude = track[i][1]

  track[i][3] = arccos(Math.cos(radians(90-prev_latitude)) * Math.cos(radians(90-latitude)) +
      Math.sin(radians(90-prev_latitude)) * Math.sin(radians(90-latitude)) *
      Math.cos(radians(prev_longitude-longitude))) *6371000

  total_distance += track[i][3]
  track[i][4] = total_distance
end

# build an array with two columns: Td, Elevation
puts "prepare elevation and distance"
distance_elevation = {}
distance_latitude = {}
distance_longitude = {}

track.map do |point|
  distance_elevation.merge!(point[4] => point[2])
  distance_latitude.merge!(point[4] => point[0])
  distance_longitude.merge!(point[4] => point[1])
end

# interpolate points at a given interval
require 'interpolator'
puts "reading data for interpolations"
elevation_table = Interpolator::Table.new(distance_elevation)
elevation_table.style = 5 # 1=linear, 2=lagrange, 3=lagrange3, 4=cubic, 5=spline

latitude_table = Interpolator::Table.new(distance_latitude)
latitude_table.style = 5 # 1=linear, 2=lagrange, 3=lagrange3, 4=cubic, 5=spline

longitude_table = Interpolator::Table.new(distance_longitude)
longitude_table.style = 5 # 1=linear, 2=lagrange, 3=lagrange3, 4=cubic, 5=spline

# output the new array (Td, elevation, slope)
interval = 2 # in meters
smooth_track = [["Total distance", "Latitude", "Longitude", "Elevation", "Slope", "Heading", "SVURL"]]
old_latitude = 0
old_longitude = 0
old_elevation = 0

puts "total distance = #{total_distance.floor}m"
puts "checkpoints = #{total_distance.floor/interval} points"
puts "smoothing gps track (1 dot = #{500*interval}m)"

(0..total_distance/interval).each do |index|
  int_latitude = latitude_table.interpolate(index * interval)
  int_longitude = longitude_table.interpolate(index * interval)
  int_elevation = elevation_table.interpolate(index * interval)

  # every coord in deg
  deg_old_latitude = old_latitude * Math::PI / 180.000000
  deg_old_longitude = old_longitude * Math::PI / 180.000000
  deg_int_latitude = int_latitude * Math::PI / 180.000000
  deg_int_longitude = int_longitude * Math::PI / 180.000000

  bearing_radians = Math.atan2( Math.cos(deg_old_latitude) * Math.sin(deg_int_latitude) -
    Math.sin(deg_old_latitude) * Math.cos(deg_int_latitude) * Math.cos(deg_int_longitude-deg_old_longitude),
      Math.sin(deg_int_longitude-deg_old_longitude) * Math.cos(deg_int_latitude) ) % (2 * Math::PI)

  bearing_degrees = bearing_radians * 180.000000 / Math::PI

  slope = (int_elevation - old_elevation) / interval
  slope_angle = Math.atan(slope)

  svurl = "http://maps.googleapis.com/maps/api/streetview?size=640x640&location=#{int_latitude},#{int_longitude}&heading=#{bearing_degrees}&fov=120&pitch=0&sensor=false&key=AIzaSyAEL0_1Syy9c1ycUH5xNNK2QRt3DbZT5g8"

  smooth_track << [index*2, int_latitude, int_longitude, int_elevation, slope_angle, bearing_degrees.floor, svurl]

  old_latitude = int_latitude
  old_longitude = int_longitude
  old_elevation = int_elevation

  putc '.' if index % 500 == 0
end
puts "done"

# write output csv file
puts "writing output track"
output_csv_file = "./tracks/#{selected_track}/#{selected_track}_smooth.csv"
CSV.open(output_csv_file, "wb") do |csv|
  smooth_track.each do |row|
    csv << row
  end
end

puts "Downloading SV cache"
(smooth_track - [["Total distance", "Latitude", "Longitude", "Elevation", "Slope", "Heading", "SVURL"]]).each do |point|
  key = point[0]
  url = point[6]

  puts "Key = #{key}"
  command = "curl '#{url}' > ./tracks/#{selected_track}/svcache/sv-#{key.to_s.rjust(8, '0')}.jpg"
  system(command)
end
puts "done"

puts "there you go sir!"



# TODO: calculate slope with more checkpoints
# test points for heading calculation
# 1 46.362093,22.873535
# 2 48.04871,27.268066
# 3 44.166445,21.09375
# 4 48.748945,20.720215
# 5 50.035974,23.554688
# 6 44.087585,23.752441





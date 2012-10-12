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
puts "smoothing gps track (1 dot = 1km)"
smooth_track = [["Total distance", "Latitude", "Longitude", "Elevation"]]
(0..total_distance/2).each do |index|
  smooth_track << [index*2, latitude_table.interpolate(index*2),
      longitude_table.interpolate(index*2), elevation_table.interpolate(index*2)]
  putc '.' if index%500 == 0
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

# TODO: calculate slope
# TODO: calculate heading
# TODO: get streetview image (heading required)
# http://maps.googleapis.com/maps/api/streetview?size=640x640&location=56.960654,-2.201815&heading=250&fov=120&pitch=0&sensor=false&key=AIzaSyAEL0_1Syy9c1ycUH5xNNK2QRt3DbZT5g8

puts "there you go sir!"













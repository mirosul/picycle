# client script

require 'zmq'

BIND_TO = 'tcp://127.0.0.1:5555'
TICK_DISTANCE = 559 # mm
SPEED_TICK_RESOLUTION = 5 # speed measured between last 5 ticks

def select_track
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

  selected_track
end

# select existing track
selected_track = select_track
csv_file = "./tracks/#{selected_track}/#{selected_track}_smooth.csv"


puts "Connecting to tick-factory"
ctx = ZMQ::Context.new(1)
s = ctx.socket(ZMQ::SUB);
s.setsockopt(ZMQ::SUBSCRIBE, "")
s.connect(BIND_TO);
puts "connected"

msg = '000000'
distance = 0 # mm
initial_time = Time.now
speed_ticks = 0
current_speed = "unknown"

# TODO - array
speed_initial_time_minus_5 = 0
speed_initial_time_minus_4 = 0
speed_initial_time_minus_3 = 0
speed_initial_time_minus_2 = 0
speed_initial_time_minus_1 = 0

puts "Detecting movement..."
loop do
  msg = s.recv(0)

  current_time = Time.now
  current_speed =  (1.0 * TICK_DISTANCE / 1000000.0 * SPEED_TICK_RESOLUTION) / ((current_time - speed_initial_time_minus_5).to_f / 3600.0)
  average_speed =  (1.0 * distance / 1000000.0) / ((current_time - initial_time).to_f / 3600.0)

  distance = distance + TICK_DISTANCE
  puts "total distance: #{"%9.2f" % (distance/1000.0)} m, speed: #{"%8.2f" % current_speed} km/h, average speed: #{"%8.2f" % average_speed} km/h"

  img = distance / 2000 * 2
  image_file = "./tracks/#{selected_track}/svcache/sv-#{img.to_s.rjust(8, '0')}.jpg"
  puts image_file

  # TODO - shift right array
  speed_initial_time_minus_5 = speed_initial_time_minus_4
  speed_initial_time_minus_4 = speed_initial_time_minus_3
  speed_initial_time_minus_3 = speed_initial_time_minus_2
  speed_initial_time_minus_2 = speed_initial_time_minus_1
  speed_initial_time_minus_1 = current_time
end

puts "Diconnecting"
s.setsockopt(ZMQ::UNSUBSCRIBE, "PICYCLE")
s.close
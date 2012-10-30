# client script

require 'zmq'

CONTROL_QUEUE = 'tcp://127.0.0.1:5556'
TICK_DISTANCE = 559 # mm
SPEED_TICK_RESOLUTION = 5 # speed measured between last 5 ticks

puts "Connecting to blacksmith ..."
ctx = ZMQ::Context.new(1)
control_queue = ctx.socket(ZMQ::REQ);
control_queue.connect(CONTROL_QUEUE);
puts "Connected."

loop do
  puts "Command: "
  command = gets
  command = 'status' if command.chomp == ''

  control_queue.send(command)
  puts control_queue.recv
end

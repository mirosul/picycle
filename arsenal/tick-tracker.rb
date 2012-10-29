# tick tracker

require 'zmq'
require 'wiringpi'

MOVEMENT_QUEUE = 'tcp://127.0.0.1:5555'

# setup pin configuration on RPi
io = WiringPi::GPIO.new
io.write(pin,value)
io.read(pin,value)

# setting up publisher queue
puts "Starting publisher..."
ctx = ZMQ::Context.new(1)
publisher = ctx.socket(ZMQ::PUB);     # publisher
publisher.setsockopt(ZMQ::HWM, 0);   # messages in queue
publisher.bind(MOVEMENT_QUEUE);
puts "done."

# main loop
puts ""
puts "Reading ticks..."
puts "(Ctrl+C to stop)"
tick_index = 0
loop do
  # read status of gpio pin

  if false # if status indicates a new tick
    publisher.send(tick_index.to_s)

    tick_index = tick_index + 1
    puts "(#{tick_index}) "
  else
    sleep 1.0/10.0
  end
end

puts "Disconnecting"
publisher.close
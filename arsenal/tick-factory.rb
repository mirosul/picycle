# tick generator

require 'zmq'

INTERVAL = [1.0/3.0, 1.0/3.0, 1.0/3.0, 1.0/3.5, 1.0/3.5, 1.0/3.5, 1.0/3.9, 1.0/3.9, 1.0/3.9, 1.0/4.0,
  1.0/4.0, 1.0/4.0, 1.0/4.0, 1.0/3.8, 1.0/3.8, 1.0/3.8, 1.0/3.8, 1.0/3.3, 1.0/3.3, 1.0/3.3, 1.0/3.3]

MOVEMENT_QUEUE = 'tcp://127.0.0.1:5555'

puts "Starting publisher..."
ctx = ZMQ::Context.new(1)
publisher = ctx.socket(ZMQ::PUB);     # publisher
publisher.setsockopt(ZMQ::HWM, 0);   # 10 messages in queue
publisher.bind(MOVEMENT_QUEUE);
puts "done."

puts ""
puts "Starting ticks..."
puts "(Ctrl+C to stop)"
i = 0
max_index = INTERVAL.count
tick_index = 0
loop do
  publisher.send(tick_index.to_s)

  sleep INTERVAL[i]

  tick_index = tick_index + 1
  i = i + 1

  i = 0 if i == max_index
  putc "."
end

puts "Disconnecting"
publisher.close
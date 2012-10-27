# tick generator

require 'zmq'

INTERVAL = [1.0/3.0, 1.0/3.0, 1.0/3.0, 1.0/3.5, 1.0/3.5, 1.0/3.5, 1.0/3.9, 1.0/3.9, 1.0/3.9, 1.0/4.0,
  1.0/4.0, 1.0/4.0, 1.0/4.0, 1.0/3.8, 1.0/3.8, 1.0/3.8, 1.0/3.8, 1.0/3.3, 1.0/3.3, 1.0/3.3, 1.0/3.3]

BIND_TO = 'tcp://127.0.0.1:5555'


puts "Starting publisher..."
ctx = ZMQ::Context.new(1)
s = ctx.socket(ZMQ::PUB);     # publisher
s.setsockopt(ZMQ::HWM, 10);   # 10 messages in queue
s.setsockopt(ZMQ::IDENTITY, "PICYCLE");   # 10 messages in queue
s.bind(BIND_TO);
puts "done."


puts ""
puts "Starting ticks..."
puts "(Ctrl+C to stop)"
i = 0
max_index = INTERVAL.count
tick_index = 0
loop do
  s.send(tick_index.to_s)

  sleep 1.0/10

  tick_index = tick_index + 1
  i = i + 1

  i = 0 if i == max_index
  puts "(#{tick_index}-#{i}) "
end

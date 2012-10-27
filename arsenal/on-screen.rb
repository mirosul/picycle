# client script

require 'zmq'

BIND_TO = 'tcp://127.0.0.1:5555'

ctx = ZMQ::Context.new(1)
s = ctx.socket(ZMQ::SUB);
s.connect(BIND_TO);

s.setsockopt(ZMQ::SUBSCRIBE, "PICYCLE")














s.setsockopt(ZMQ::UNSUBSCRIBE, "PICYCLE")
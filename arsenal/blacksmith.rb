### BLACKSMITH ###

# reads movement q (tick factory / tick tracker)
# has a state
# process data from movement loop depending on it's state
# reads control q (cyclop) and changes state accordingly
# writes on control q

# available commands: LOAD, START, STOP, PAUSE, RESUME, POLL
# available returns: serialized values containing the current state or the data (POLL)

# control q (q2) is a bidirectional queue

require 'zmq'

MOVEMENT_QUEUE = 'tcp://127.0.0.1:5555'
CONTROL_QUEUE = 'tcp://127.0.0.1:5556'

TICK_DISTANCE = 559 # mm
SPEED_TICK_RESOLUTION = 5 # speed measured between last 5 ticks

puts "Connecting to tick-factory or tick-tracker"
ctx = ZMQ::Context.new(1)
s = ctx.socket(ZMQ::SUB);
s.setsockopt(ZMQ::SUBSCRIBE, "")
s.connect(MOVEMENT_QUEUE);
puts "Connected."


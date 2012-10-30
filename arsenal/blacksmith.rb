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

ctx = ZMQ::Context.new(1)

puts "Connecting to tick-factory or tick-tracker ..."
movement_queue = ctx.socket(ZMQ::SUB);
movement_queue.setsockopt(ZMQ::SUBSCRIBE, "")
movement_queue.connect(MOVEMENT_QUEUE);
puts "Connected."

puts "Connecting to cyclop ..."
control_queue = ctx.socket(ZMQ::REP);
control_queue.bind(CONTROL_QUEUE);
puts "Connected."

msg = "000000"

# reset_counters
  distance = 0 # mm
  initial_time = Time.now
  current_time = Time.now
  speed_ticks = 0
  current_speed = 0
  time_interval = 0
  average_speed = 0

  state = {}
  state['counting'] = 0
  selected_track = ''

  distance_text = ''
  speed_text = ''
  image_file = ''

  speed_initial_time_minus_5 = 0
  speed_initial_time_minus_4 = 0
  speed_initial_time_minus_3 = 0
  speed_initial_time_minus_2 = 0
  speed_initial_time_minus_1 = 0
# end reset counters

loop do
  # process movement queue
  msg = movement_queue.recv(ZMQ::NOBLOCK)
  unless msg.nil?
    puts "MV: recv " + msg
    if state['counting'] == 1
      current_time = Time.now
      time_interval = (current_time - initial_time).to_f
      current_speed =  (1.0 * TICK_DISTANCE / 1000000.0 * SPEED_TICK_RESOLUTION) / ((current_time - speed_initial_time_minus_5).to_f / 3600.0)
      average_speed =  (1.0 * distance / 1000000.0) / (time_interval / 3600.0)

      distance = distance + TICK_DISTANCE
      distance_text = "Total distance: #{"%9.2f" % (distance/1000.0)} m"
      speed_text = "speed: #{"%8.2f" % current_speed} km/h, average speed: #{"%8.2f" % average_speed} km/h"

      img = distance / 1000 / 2 * 2
      image_file = "tracks/#{selected_track}/svcache/sv-#{img.to_s.rjust(8, '0')}.jpg"

      # TODO - shift right array
      speed_initial_time_minus_5 = speed_initial_time_minus_4
      speed_initial_time_minus_4 = speed_initial_time_minus_3
      speed_initial_time_minus_3 = speed_initial_time_minus_2
      speed_initial_time_minus_2 = speed_initial_time_minus_1
      speed_initial_time_minus_1 = current_time
    end
  end

  # process control queue
  msg = control_queue.recv(ZMQ::NOBLOCK)
  unless msg.nil?
    msg.chomp!
    puts "CTRL: recv " + msg
    response = ""

    if msg == "ping"
      response = "pong"
    end

    if msg == "status"
      response = state.to_s + ", " + selected_track + ", " + distance_text + ", " + speed_text
    end

    if msg[0..3] == "load"
      if state['counting'] == 1
        response = "activity started. stop first"
      else
        distance = 0 # mm
        initial_time = Time.now
        speed_ticks = 0
        current_speed = 0
        time_interval = 0
        average_speed = 0

        state = {}
        state['counting'] = 0

        distance_text = ''
        speed_text = ''

        speed_initial_time_minus_5 = 0
        speed_initial_time_minus_4 = 0
        speed_initial_time_minus_3 = 0
        speed_initial_time_minus_2 = 0
        speed_initial_time_minus_1 = 0

        selected_track = msg[5..999]

        response = "loaded"
      end
    end

    if msg == "start"
      if state['counting'] == 1
        response = "activity already started. stop first"
      else
        if selected_track == ''
          response = "nothing to start. load track first"
        else
          distance = 0 # mm
          initial_time = Time.now
          speed_ticks = 0
          current_speed = 0
          time_interval = 0
          average_speed = 0

          state = {}
          state['counting'] = 0

          distance_text = ''
          speed_text = ''

          speed_initial_time_minus_5 = 0
          speed_initial_time_minus_4 = 0
          speed_initial_time_minus_3 = 0
          speed_initial_time_minus_2 = 0
          speed_initial_time_minus_1 = 0

          state['counting'] = 1
          response = "started"
        end
      end
    end

    if msg == "stop"
      if state['counting'] == 1
        distance = 0 # mm
        initial_time = Time.now
        speed_ticks = 0
        current_speed = 0
        time_interval = 0
        average_speed = 0

        state = {}
        state['counting'] = 0

        distance_text = ''
        speed_text = ''

        speed_initial_time_minus_5 = 0
        speed_initial_time_minus_4 = 0
        speed_initial_time_minus_3 = 0
        speed_initial_time_minus_2 = 0
        speed_initial_time_minus_1 = 0

        state['counting'] = 0
        response = "stopped"
      else
        response = "nothing to stop. start first"
      end
    end

    if msg == "get_distance"
      response = ("%15.0f" % distance).strip
    end

    if msg == "get_image"
      response = image_file
    end

    if msg == "get_current_speed"
      response = ("%8.2f" % current_speed).strip
    end

    if msg == "get_average_speed"
      response = ("%8.2f" % average_speed).strip
    end

    if msg == "get_timer"
      response = time_interval.to_s
    end

    if msg == "get_selected_track"
      response = selected_track
    end

    if msg == "shutdown"
      control_queue.send("down", ZMQ::NOBLOCK)
      break
    end

    control_queue.send(response, ZMQ::NOBLOCK)
    puts "CTRL: send " + response
  end

  sleep 1.0/10.0
  putc '.'
end


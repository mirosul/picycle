# client script

require 'zmq'
require 'gtk2'

BIND_TO = 'tcp://127.0.0.1:5556'
TICK_DISTANCE = 559 # mm
SPEED_TICK_RESOLUTION = 5 # speed measured between last 5 ticks

class RubyApp < Gtk::Window
  @@subscriber

  def initialize
    super

    set_title "Center"
    signal_connect "destroy" do
      destroy_zmq
      Gtk.main_quit
    end

    init_ui
    init_variables
    init_zmq
    init_timer
    show_all
  end

  def init_zmq
    set_status "Connecting to tick-factory..."
    ctx = ZMQ::Context.new(1)
    @@subscriber = ctx.socket(ZMQ::SUB);
    @@subscriber.setsockopt(ZMQ::SUBSCRIBE, "")
    @@subscriber.connect(BIND_TO);
    set_status "Connected."
  end

  def destroy_zmq
    @@subscriber.setsockopt(ZMQ::UNSUBSCRIBE, "")
    @@subscriber.close
  end

  def init_timer
    Gtk.timeout_add(1000) do
      @@selected_track = 'solaison-part'
      msg = '00000000'
      msg = @@subscriber.recv(0)

      current_time = Time.now
      current_speed =  (1.0 * TICK_DISTANCE / 1000000.0 * SPEED_TICK_RESOLUTION) / ((current_time - @@speed_initial_time_minus_5).to_f / 3600.0)
      average_speed =  (1.0 * @@distance / 1000000.0) / ((current_time - @@initial_time).to_f / 3600.0)

      @@distance = @@distance + TICK_DISTANCE
      @@distance_ctl.text = "Total distance: #{"%9.2f" % (@@distance/1000.0)} m"
      # set_status "speed: #{"%8.2f" % current_speed} km/h, average speed: #{"%8.2f" % average_speed} km/h"

      img = @@distance / 2000 * 2
      image_file = "tracks/#{@@selected_track}/svcache/sv-#{img.to_s.rjust(8, '0')}.jpg"
      set_status image_file
      @@image_ctl.set(image_file)
      @@image_ctl.queue_draw

      # TODO - shift right array
      @@speed_initial_time_minus_5 = @@speed_initial_time_minus_4
      @@speed_initial_time_minus_4 = @@speed_initial_time_minus_3
      @@speed_initial_time_minus_3 = @@speed_initial_time_minus_2
      @@speed_initial_time_minus_2 = @@speed_initial_time_minus_1
      @@speed_initial_time_minus_1 = current_time
    end
  end

  def set_status status
    @@status.buffer.text = @@status.buffer.text + "\n" + status
  end

  # def start_button_click(sender)
  def init_variables
    # select existing track
    @@selected_track = @@tracks_ctl.active_text
    set_status @@selected_track
    csv_file = "./tracks/#{@@selected_track}/#{@@selected_track}_smooth.csv"

    @@distance = 0 # mm
    @@initial_time = Time.now
    @@speed_ticks = 0

    # TODO - array
    @@speed_initial_time_minus_5 = 0
    @@speed_initial_time_minus_4 = 0
    @@speed_initial_time_minus_3 = 0
    @@speed_initial_time_minus_2 = 0
    @@speed_initial_time_minus_1 = 0

    set_status "Detecting movement..."
  end

  def init_ui
    # create container
    @@fixed = Gtk::Fixed.new
    add @@fixed

    # status label
    @@status = Gtk::TextView.new
    @@status.set_size_request 300, 60
    @@fixed.put @@status, 210, 10

    # distance label
    @@distance_ctl = Gtk::Label.new
    @@distance_ctl.set_size_request 300, 60
    @@fixed.put @@distance_ctl, 40, 150

    # streetview image
    @@image_ctl = Gtk::Image.new("tracks/solaison-part/svcache/sv-00000000.jpg")
    @@fixed.put @@image_ctl, 10, 80

    # available tracks
    tracks = []
    available_tracks = `ls ./tracks`
    available_tracks.each_line do |track|
      tracks << track.strip
    end

    @@tracks_ctl = Gtk::ComboBox.new
    tracks.each_with_index do |track, index|
      @@tracks_ctl.append_text "#{track}#{ index == 0 ? ' (default)' : ''}"
    end
    @@tracks_ctl.set_active 0
    @@fixed.put @@tracks_ctl, 10, 10

    # start button
    button = Gtk::Button.new "Start reading"
    button.set_size_request 80, 35
    # button.signal_connect "clicked" do |sender|
    #   start_button_click(sender)
    # end
    @@fixed.put button, 10, 40

    # window properties
    set_default_size 800, 800
    set_window_position Gtk::Window::POS_CENTER
  end
end

Gtk.init
window = RubyApp.new
Gtk.main

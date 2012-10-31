# client script

require 'zmq'
require 'gtk2'

CONTROL_QUEUE = 'tcp://127.0.0.1:5556'
TICK_DISTANCE = 559 # mm
SPEED_TICK_RESOLUTION = 5 # speed measured between last 5 ticks

class Cyclop < Gtk::Window
  @@control_queue
  @@distance_ctl
  @@tracks_ctl
  @@timer

  def initialize
    super
    init_ui
    init_zmq
    show_all
  end

  def init_zmq
    ctx = ZMQ::Context.new(1)
    @@control_queue = ctx.socket(ZMQ::REQ);
    @@control_queue.connect(CONTROL_QUEUE);
  end

  def destroy_zmq
    @@control_queue.close
  end

  def set_status status
    @@status.buffer.text = status
  end

  def init_ui
    # create container
    @@fixed = Gtk::Fixed.new
    add @@fixed

    # streetview image
    @@image_ctl = Gtk::Image.new("tracks/solaison-part/svcache/sv-00000000.jpg")
    @@fixed.put @@image_ctl, 560, 0

    # status label
    @@status = Gtk::TextView.new
    @@status.set_size_request 560, 50
    @@fixed.put @@status, 0, 590

    # available tracks
    tracks = []
    available_tracks = `ls ./tracks`
    available_tracks.each_line do |track|
      tracks << track.strip
    end

    @@tracks_ctl = Gtk::ComboBox.new
    tracks.each_with_index do |track, index|
      @@tracks_ctl.append_text track
    end
    @@tracks_ctl.set_active 0
    @@tracks_ctl.set_size_request 300, 25
    @@fixed.put @@tracks_ctl, 10, 10

    # select track button
    select_track_button = Gtk::Button.new "Select track"
    select_track_button.set_size_request 120, 25
    select_track_button.signal_connect "clicked" do |sender|
      select_track_click(sender)
    end
    @@fixed.put select_track_button, 320, 10

    # start track button
    start_track_button = Gtk::Button.new "Star trek"
    start_track_button.set_size_request 120, 25
    start_track_button.signal_connect "clicked" do |sender|
      start_track_click(sender)
    end
    @@fixed.put start_track_button, 10, 45

    # start track button
    stop_track_button = Gtk::Button.new "Stop track"
    stop_track_button.set_size_request 120, 25
    stop_track_button.signal_connect "clicked" do |sender|
      stop_track_click(sender)
    end
    @@fixed.put stop_track_button, 140, 45

    # start track button
    status_button = Gtk::Button.new "Status"
    status_button.set_size_request 120, 25
    status_button.signal_connect "clicked" do |sender|
      status_click(sender)
    end
    @@fixed.put status_button, 270, 45


    ### INDICATORS

    # distance label
    @@distance_ctl = Gtk::Label.new("Distance: ")
    @@distance_ctl.set_size_request 520, 25
    @@distance_ctl.set_alignment 0, 0
    @@fixed.put @@distance_ctl, 10, 80

    # timer label
    @@timer_ctl = Gtk::Label.new("Timer: ")
    @@timer_ctl.set_size_request 520, 25
    @@timer_ctl.set_alignment 0, 0
    @@fixed.put @@timer_ctl, 10, 115

    # current speed label
    @@current_speed_ctl = Gtk::Label.new("Current speed: ")
    @@current_speed_ctl.set_size_request 520, 25
    @@current_speed_ctl.set_alignment 0, 0
    @@fixed.put @@current_speed_ctl, 10, 150

    # average speed label
    @@average_speed_ctl = Gtk::Label.new("Average speed: ")
    @@average_speed_ctl.set_size_request 520, 25
    @@average_speed_ctl.set_alignment 0, 0
    @@fixed.put @@average_speed_ctl, 10, 185



    # window properties
    set_title "Cyclop"
    set_default_size 1200, 640
    set_window_position Gtk::Window::POS_CENTER

    signal_connect "destroy" do
      destroy_zmq
      Gtk.main_quit
    end

    @@timer = Thread.new do
      Thread.stop
      while true do
        status_click(nil)
        sleep 1.0/4.0
      end
    end

  end

  def select_track_click(sender)
    @@control_queue.send("load " + @@tracks_ctl.active_text)
    set_status @@control_queue.recv
  end

  def start_track_click(sender)
    @@control_queue.send("start")
    set_status @@control_queue.recv

    @@timer.run
  end

  def stop_track_click(sender)
    @@control_queue.send("stop")
    set_status @@control_queue.recv

    @@timer.kill
  end

  def status_click(sender)
    # for debugging purpose only
    # @@control_queue.send("status")
    # set_status @@control_queue.recv

    @@control_queue.send("get_params")
    params = @@control_queue.recv.split(";")

    @@distance_ctl.set_markup("Distance: <b>#{("%12.2f" % (params[0].to_i / 1000.0)).strip} m</b>")
    @@timer_ctl.set_markup("Timer: <b>#{("%12.0f" % params[4].to_i).strip} s</b>")
    @@current_speed_ctl.set_markup("Current speed: <b>#{("%12.2f" % params[1].to_f).strip} km/h</b>")
    @@average_speed_ctl.set_markup("Average speed: <b>#{("%12.2f" % params[2].to_f).strip} km/h</b>")
    @@image_ctl.set(params[3])

    return true
  end

end

Gtk.init
window = Cyclop.new
Gtk.main

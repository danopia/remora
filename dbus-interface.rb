require 'rubygems'
require 'dbus'

class DBusRemora < DBus::Object
  attr_accessor :client
  
  def initialize client, path
    @@client = client
    super path
  end
  
  # Create an interface. 
  dbus_interface "org.remora.Service.Queue" do
    dbus_method :now_playing, "out res:s" do
      info = @@client.now_playing
      next "No song is playing" unless info
      "#{info['Name']} - #{info['ArtistName']} - #{info['AlbumName']}"
    end
  end
end

def run_dbus client
  # Choose the bus (could also be DBus::system_bus)
  bus = DBus::session_bus

  bus.request_service("my.failure.Service") rescue nil

  # Define the service name
  service = bus.request_service("org.remora.Service")

  # Set the object path
  obj = DBusRemora.new(client, "/org/remora/Service/Player")
  # Export it!
  service.export(obj)

  Thread.new do
    # Now listen to incoming requests
    main = DBus::Main.new
    main << bus
    main.run
  end
end

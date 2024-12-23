require 'sinatra'
require 'vapi'
require 'dotenv/load'
require 'json'
require 'import_csv'
require_relative 'lib/load_event_types_config'

require 'pry'

def check_event_config(config_hash)
  remote_config = VAPI.get_helix_event_types

  present_events = []
  missing_events = []
  config_hash.each do |event_type, mappings|
    exists = remote_config.any? { |remote_event| remote_event[:name] == event_type }
    if exists
      present_events << event_type
    else
      missing_events << event_type
    end
  end

  # TODO: for each present event, check that the schema matches. 
  # If not, exit on error and warn that create_helix_event_types.rb is destructive
  # present_events.each


  unless missing_events.empty?
    puts "Warning: The following event types are missing from remote configuration:"
    missing_events.each { |event| puts "* \"#{event}\"" }
    puts "Please run create_helix_event_types.rb to create them."
    exit(1)
  end

end

api_key = ENV['VERKADA_API_KEY']
VAPI = Vapi.new(api_key)

devices_config = import_csv('devices_config.csv')
binding.pry
event_types_config = load_event_types_config('event_types_config.csv')

check_event_config(event_types_config)

get '/' do
  "Under Construction"
end

post '/event' do
  body = JSON.parse(request.body.read)
end

post '/event/withtime' do
  body = JSON.parse(request.body.read)
end
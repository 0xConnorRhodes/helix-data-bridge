require 'vapi'
require 'dotenv/load'
require_relative 'lib/load_event_types_config'
require 'pry'

vapi = Vapi.new(ENV['VERKADA_API_KEY'])
event_types_config = load_event_types_config('event_types_config.csv')
helix_event_types = vapi.get_helix_event_types

present_events = []
missing_events = []
event_types_config.each do |local_type, mappings|
  helix_event_types.each do |remote_type|
    if remote_type[:name] == local_type
      present_events << local_type
    else
      missing_events << local_type
    end
  end
end
present_events.uniq!
missing_events.uniq!

binding.pry
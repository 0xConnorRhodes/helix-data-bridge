require 'vapi'
require 'dotenv/load'

def compare_event_types(local_config:, remote_config:)
  present_events = []
  missing_events = []
  local_config.each do |local_type, mappings|
  	remote_config.each do |remote_type|
  		if remote_type[:name] == local_type
  			present_events << local_type
  		else
  			missing_events << local_type
  		end
  	end
  end
  missing_events -= present_events
  present_events.uniq!
  missing_events.uniq!

  return present_events, missing_events
end
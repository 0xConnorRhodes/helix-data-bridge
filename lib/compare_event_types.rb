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

def check_event_config(config_hash)
  helix_event_types = VAPI.get_helix_event_types

  present_events, missing_events = compare_event_types(
  	local_config: config_hash, 
  	remote_config: helix_event_types
  )

  present_events.each do |pres_event|
  	remote_event_type = helix_event_types.find {|event| event[:name] == pres_event}
  	remote_schema = remote_event_type[:event_schema]

  	local_schema = config_hash[pres_event].each_with_object({}) do |mapping, schema|
  		schema[mapping[:helix_key]] = mapping[:data_type]
  	end
  	local_schema.transform_keys!(&:to_sym)

    unless missing_events.empty?
      puts "Warning: The following event types are missing from remote configuration:"
      missing_events.each { |event| puts "* \"#{event}\"" }
      puts "Please run create_helix_event_types.rb to create them."
      return false
      exit(1)
    end

		unless local_schema == remote_schema
			puts "WARNING: Event type \"#{pres_event}\" already exists, but it does not match the local event type config"
			puts "The local config schema is:"
			puts JSON.pretty_generate(JSON.parse(local_schema.to_json))
			puts "\n"

			puts "The remote config schema is:"
			puts JSON.pretty_generate(JSON.parse(remote_schema.to_json))
			puts "\n"

			puts "If you want to overwrite the remote schema with the local schema, run create_helix_event_types.rb"
      return false
			exit(1)
		end
  end
  true
end
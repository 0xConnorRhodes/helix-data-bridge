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
  helix_event_types = $vapi.get_helix_event_types

  message = []
  data_purpose_check, data_purpose_message = check_data_purpose_field(config_hash)
  message << data_purpose_message unless data_purpose_check

  sanitized_hash = config_hash.transform_values do |mappings|
    mappings
      .reject { |mapping| mapping[:data_purpose] == "event type id" }
      .map { |mapping| mapping.reject { |k, v| v.nil? || k == :data_purpose } }
  end

  present_events, missing_events = compare_event_types(
  	local_config: sanitized_hash, 
  	remote_config: helix_event_types
  )

  present_events.each do |pres_event|
  	remote_event_type = helix_event_types.find {|event| event[:name] == pres_event}
  	remote_schema = remote_event_type[:event_schema]

  	local_schema = sanitized_hash[pres_event].each_with_object({}) do |mapping, schema|
  		schema[mapping[:helix_key]] = mapping[:data_type]
  	end
  	local_schema.transform_keys!(&:to_sym)

    unless missing_events.empty?
      message << "<p>WARNING: The following event types are missing from remote configuration:<ul>"
      missing_events.each { |event| message << "<li> #{event}</li>" }
      message << "</ul>Please run create_helix_event_types.rb to create them.</p>"
    end

  	unless local_schema == remote_schema
  		message << "<p>WARNING: Event type \"#{pres_event}\" already exists, but it does not match the local event type config</p>"
  		message << "<p>The local config schema is:<br>"
  		message << JSON.pretty_generate(JSON.parse(local_schema.to_json))
  		message << "</p>"
  
  		message << "<p>The remote config schema is:<br>"
  		message << JSON.pretty_generate(JSON.parse(remote_schema.to_json))
  		message << "</p>"
  
  		message << "<p>If you want to overwrite the remote schema with the local schema, run create_helix_event_types.rb</p>"
  	end
  end

  if message.any?
    message.uniq!
    message = message.select { |m| m.start_with?("<p>ERROR: Invalid data_purpose") } if message.any? { |m| m.start_with?("<p>ERROR: Invalid data_purpose") }
    return message
  else
    return ["<p>Event types configuration checks passed.</p>"]
  end
end

def check_data_purpose_field(config_hash)
  valid_data_purposes = ["device id", "event type id", "metric"]
  config_hash.each do |event_type, mappings|
    mappings.each do |mapping|
      unless valid_data_purposes.include?(mapping[:data_purpose])
        message =  "<p>ERROR: Invalid data_purpose '#{mapping[:data_purpose]}' for event type '#{event_type}'</p>"
        return false, message
      end
    end
  end
end

def check_devices_config
  nil
end
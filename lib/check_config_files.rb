def compare_event_types(local_config:, remote_config:)
  present_events = []
  local_config.each do |local_type, mappings|
  	remote_config.each do |remote_type|
  		if remote_type[:name] == local_type
  			present_events << local_type
  		end
  	end
  end
  present_events.uniq!

  return present_events
end

def check_event_config(config_hash)
  helix_event_types = $vapi.get_helix_event_types

  required_keys = ["remote_key", "helix_key", "data_type", "data_purpose"]
  
  config_hash.each do |event_type, mappings|
    mappings.each do |mapping|
      missing_keys = required_keys.map(&:to_sym) - mapping.keys
      if missing_keys.any?
        # style missing keys to match csv convention
        styled_missing_keys = missing_keys.map(&:to_s).map{|i| i.gsub('_', ' ')}.map{|i| i.split.map(&:capitalize).join(' ')}
        return "EVENT TYPE ERROR: Missing required keys in config: #{styled_missing_keys.join(', ')}"
      end
    end
  end

  message = []
  data_purpose_check, data_purpose_message = check_data_purpose_field(config_hash)
  message << data_purpose_message unless data_purpose_check

  sanitized_hash = config_hash.transform_values do |mappings|
    mappings
      .reject { |mapping| mapping[:data_purpose] == "event type id" }
      .map { |mapping| mapping.reject { |k, v| v.nil? || k == :data_purpose } }
  end

  present_events = compare_event_types(
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

  	unless local_schema == remote_schema
  		message << "EVENT TYPE WARNING: Event type \"#{pres_event}\" already exists, but it does not match the local event type config"
  		message << "The local config schema is:"
  		message << JSON.pretty_generate(JSON.parse(local_schema.to_json))
  
  		message << "The remote config schema is:"
  		message << JSON.pretty_generate(JSON.parse(remote_schema.to_json))
  
  		message << "Please reconcile the event types by modifying the config file or the event type schema in Command. See <a href='https://apidocs.verkada.com/reference/getting-started' target='_blank'>here</a> for more information."
  	end
  end

  if message.any?
    message.uniq!
    message = message.select { |m| m.start_with?("EVENT TYPE ERROR: Invalid data_purpose") } if message.any? { |m| m.start_with?("EVENT TYPE ERROR: Invalid data_purpose") }
    return message.join("\n")
  else
    return "Event types configuration checks passed."
  end
end

def check_data_purpose_field(config_hash)
  valid_data_purposes = ["device id", "event type id", "metric"]
  config_hash.each do |event_type, mappings|
    mappings.each do |mapping|
      unless valid_data_purposes.include?(mapping[:data_purpose])
        message =  "EVENT TYPE ERROR: Invalid data_purpose '#{mapping[:data_purpose]}' for event type '#{event_type}'"
        return false, message
      end
    end
  end
end

def check_devices_config(config_array)
  message = []
  
  # Check column names
  expected_columns = ["device", "context_camera"]
  actual_columns = config_array.first&.keys&.map(&:to_s)
  
  unless actual_columns == expected_columns
    message << "DEVICE MAPPING ERROR: Invalid columns in device mappings config. Expected 'Device' and 'Context Camera', got: #{actual_columns.join(', ')}"
    return message
  end

  # Check for empty values
  config_array.each_with_index do |row, index|
    row_number = index + 1
    if row[:device].to_s.strip.empty? || row[:context_camera].to_s.strip.empty?
      message << "DEVICE MAPPING ERROR: Missing value in row #{row_number}. Both 'Device' and 'Context Camera' must have values."
    end
  end

  message.any? ? message : ["Device mappings configuration checks passed."]
end
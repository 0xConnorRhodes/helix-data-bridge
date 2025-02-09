def generate_event_timestamp(event_name, event_mappings, req_body)
# take mappings for an event and a request body
# parse the supplied time (in timezone if specified)
# else return current time

	# check if the active event type has a timestamp field specified
	if event_mappings.any? { |hash| hash[:data_purpose] == "timestamp" }
		time_config = $event_types_config[event_name].select { |h| h[:data_purpose] == "timestamp" }.first
		time_key = time_config[:remote_key]
		time_fmt = time_config&.dig(:data_type)

		if time_fmt.include?(":")
				_, timezone = time_fmt.split(":")
				ENV["TZ"] = timezone
				unix_time = Time.parse(req_body[time_key]).to_i
		else
			puts "No timezone in server config. Using timezone: #{$machine_timezone} from local machine"
			ENV["TZ"] = $machine_timezone
			unix_time = Time.parse(req_body[time_key]).to_i
		end
	else
		unix_time = Time.now.to_i
	end
  return unix_time
end
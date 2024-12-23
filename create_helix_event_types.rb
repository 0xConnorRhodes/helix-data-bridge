require 'vapi'
require 'dotenv/load'
require_relative 'lib/load_event_types_config'
require_relative 'lib/compare_event_types'
require 'json'

vapi = Vapi.new(ENV['VERKADA_API_KEY'])
event_types_config = load_event_types_config('event_types_config.csv')
helix_event_types = vapi.get_helix_event_types

present_events, missing_events = compare_event_types(
	local_config: event_types_config, 
	remote_config: helix_event_types
)

unless missing_events.empty?
  missing_events.each do |mis_event|
  	schema = event_types_config[mis_event].each_with_object({}) do |mapping, schema|
  		schema[mapping[:helix_key]] = mapping[:data_type]
  	end

  	result = vapi.create_helix_event_type(
  		name: mis_event,
  		schema: schema
  	)
  	puts "Successfully created event type: \"#{mis_event}\"" if result[:event_type_uid]
  end
end

present_events.each do |pres_event|
	remote_event_type = helix_event_types.find {|event| event[:name] == pres_event}
	remote_schema = remote_event_type[:event_schema]

	local_schema = event_types_config[pres_event].each_with_object({}) do |mapping, schema|
		schema[mapping[:helix_key]] = mapping[:data_type]
	end
	local_schema.transform_keys!(&:to_sym)

	if local_schema == remote_schema
		puts "Event type \"#{pres_event}\" already exists and is up to date"
		puts "\n"
	else
		puts "WARNING: Event type \"#{pres_event}\" already exists, but it does not match the local event type config"
		puts "The local config schema is:"
		puts JSON.pretty_generate(JSON.parse(local_schema.to_json))
		puts "\n"

		puts "The remote config schema is:"
		puts JSON.pretty_generate(JSON.parse(remote_schema.to_json))
		puts "\n"

		puts "If you want to overwrite the remote schema with the local schema, type \"OVERWRITE\""
		user_input = gets.chomp
		if user_input == "OVERWRITE"
			result = vapi.update_helix_event_type(
				uid: remote_event_type[:event_type_uid],
				name: pres_event,
				schema: local_schema
			)
			puts "Successfully updated event type: \"#{pres_event}\"" if result == 200
		else
			puts "Skipping event type \"#{pres_event}\""
		end		
	end
end
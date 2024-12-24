require 'sinatra'
require 'vapi'
require 'dotenv/load'
require 'json'
require 'import_csv'
require_relative 'lib/load_event_types_config'
require_relative 'lib/compare_event_types'

require 'pry'

api_key = ENV['VERKADA_API_KEY']
VAPI = Vapi.new(api_key)

devices_config = import_csv('devices_config.csv')
event_types_config = load_event_types_config('event_types_config.csv')
config_check = check_event_config(event_types_config)

if !check_event_config(event_types_config)
	puts "\nERROR: Failed config check. Resolve errors before running server."
	exit(1)
end

set :port, 8080

get '/' do
  "Under Construction"
end

post '/event/keyid' do
  body = JSON.parse(request.body.read)
	event_types_config.each do |event_type, mappings|
    # Find the event type mapping in this group
    event_type_mapping = mappings.find { |mapping| mapping[:data_purpose] == "event type id" }
    
    next unless event_type_mapping

		id_key = {}
		id_key[event_type_mapping[:remote_key]] = event_type_mapping[:helix_key]

		if body[id_key.keys.first] == id_key.values.first
			# TODO: add logic to generate payload for helix event
			puts "Found event type mapping for #{event_type}"
		end
  end
	return "Under Construction"
	# result = VAPI.create_helix_event(
	# 	event_type_uid: nil,
	# 	camera_id: nil,
	# 	attributes: nil,
	# 	time: nil
	# )
end

post '/debug' do
  body = JSON.parse(request.body.read)
	"test"
end

post '/event/deviceid' do
  "Under Construction"
  # body = JSON.parse(request.body.read)
end
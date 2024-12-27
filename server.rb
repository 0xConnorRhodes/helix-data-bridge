require 'sinatra'
require 'vapi'
require 'dotenv/load'
require 'json'
require 'import_csv'
require_relative 'lib/load_event_types_config'
require_relative 'lib/compare_event_types'
require_relative 'lib/check_api_key'

require 'pry'

api_key = ENV['VERKADA_API_KEY']
$vapi = Vapi.new(api_key)

devices_config = import_csv('devices_config.csv')
event_types_config = load_event_types_config('event_types_config.csv')

$api_key_status = check_api_key

if $api_key_status
  $event_config_message = check_event_config(event_types_config)
  helix_event_types = $vapi.get_helix_event_types if $api_key_status
end


set :port, 8080

get '/' do
	erb :index
end

post '/event/by/keyid' do
	body = JSON.parse(request.body.read)

	helix_event_type_config = nil # remote helix event type config
	helix_event_attributes = {} # attributes for payload in create_helix_event request
	device_id_key = nil # key with the value that maps to device id in devices_config
	event_types_config.each do |event_type_name, mappings|
 		event_type_mapping = mappings.find { |mapping| mapping[:data_purpose] == "event type id" }
		next unless event_type_mapping

		event_id_key = {} # key which identifies which Helix event type this is a request for
		event_id_key[event_type_mapping[:remote_key]] = event_type_mapping[:helix_key]

		if body[event_id_key.keys.first] == event_id_key.values.first
			helix_event_type_config = helix_event_types.select{|et| et[:name] == event_type_name}

			body.keys.each do |key|
				config_row = event_types_config[event_type_name].find{|hash| hash[:remote_key] == key}
				device_id_key = config_row[:remote_key] if config_row[:data_purpose] == "device id"
				next if config_row[:data_type].nil?
				helix_event_attributes[config_row[:helix_key]] = body[key]
			end
		end
	end

	camera_id = devices_config.find{|row| row[:device] ==  body[device_id_key]}[:context_camera]

	result = $vapi.create_helix_event(
		event_type_uid: helix_event_type_config.first[:event_type_uid],
		camera_id: camera_id,
		attributes: helix_event_attributes,
	)
	return result
end

post '/event/by/deviceid' do
	# detect device by key/value which maps to device id
	"Under Construction"
	# body = JSON.parse(request.body.read)
end
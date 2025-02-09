require 'sinatra'
require 'dotenv/load'
require 'json'
require 'time'
require 'vapi'
require 'import_csv'
require_relative 'lib/load_event_types_config'
require_relative 'lib/check_config_files'
require_relative 'lib/check_api_key'
require_relative 'lib/create_event_types'
require_relative 'lib/timezone'
require_relative 'lib/generate_event_timestamp'
require 'pry'

api_key = ENV['VERKADA_API_KEY']
$vapi = Vapi.new(api_key)

def process_config
	$api_key_status = check_api_key
  $org_id = $vapi.get_org_id if $api_key_status

	$event_types_config = load_event_types_config('event_types_config.csv') if File.exist?('event_types_config.csv')
	$devices_config = import_csv('devices_config.csv') if File.exist?('devices_config.csv')

	create_event_types($event_types_config) if File.exist?('event_types_config.csv')
  $helix_event_types = $vapi.get_helix_event_types if $api_key_status

	$machine_timezone = get_machine_timezone
end

process_config

configure do
	set :bind, '0.0.0.0'
	set :port, 80
	set :environment, :production
	set :show_exceptions, false
end

helpers do
  def protected!
    return if request.path_info.start_with?('/event')
    
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      halt 401, "Not authorized\n"
    end
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && 
    @auth.credentials == [ENV['ADMIN_USERNAME'], ENV['ADMIN_PASSWORD']]
  end
end

# Add before filter for all routes
before do
  protected!
end

get '/' do
	erb :index
end

get '/error' do
	@error = params[:error]
	@message = params[:message]
	puts "#{@error}"
	puts "ERROR NOTE: #{@message}"
	erb :error
end

post '/event/by/keyid' do
	body = JSON.parse(request.body.read)

	helix_event_type_config = nil # remote helix event type config
	helix_event_attributes = {} # attributes for payload in create_helix_event request
	device_id_key = nil # key with the value that maps to device id in devices_config

	if $event_types_config.nil? || $event_types_config.empty? || $devices_config.nil? || $devices_config.empty?
		puts "Failed request: Server configuration is missing. Have you uploaded the necessary config files?"
		halt 400, { error: "Server configuration is missing. Have you uploaded the necessary config files?" }.to_json
	end

	unix_time = nil
	$event_types_config.each do |event_type_name, mappings|
 		event_type_mapping = mappings.find { |mapping| mapping[:data_purpose] == "event type id" }
		if event_type_mapping
			id_pair = {} # key:value from event_types_config that identifies this particular event type
			id_pair[event_type_mapping[:remote_key]] = event_type_mapping[:helix_key]

			# next unless event_type_id key:value in the body matches this event type
			next unless id_pair.all? { |key, value| body[key] == value }

			helix_event_type_config = $helix_event_types.select{|et| et[:name] == event_type_name}

			body.keys.each do |key|
				config_row = $event_types_config[event_type_name].find{|hash| hash[:remote_key] == key}
				device_id_key = config_row[:remote_key] if config_row[:data_purpose] == "device id"
				next if config_row[:data_type].nil? || config_row[:data_type].start_with?("time")
				helix_event_attributes[config_row[:helix_key]] = body[key]
			end
			unix_time = generate_event_timestamp(event_type_name, mappings, body)
			break
		else
			# TODO: metric code goes here
			# if no event type, then check if metric, break once match
			unix_time = generate_event_timestamp(event_type_name, mappings, body)
			break
		end
	end

	begin
		camera_id = $devices_config.find{|row| row[:device] ==  body[device_id_key]}[:context_camera]
	rescue => e
		puts "Request body could not be parsed. It likely contains invalid data."
		puts "Please check the key names, and values."
		puts "Body: #{body}"
		halt 400, { error: "Bad request" }.to_json
	end

	result = $vapi.create_helix_event(
		event_type_uid: helix_event_type_config.first[:event_type_uid],
		camera_id: camera_id,
		attributes: helix_event_attributes,
		time: unix_time
	)
	return result
end

get '/config/api-key' do
		erb :api_key_form
end

post '/config/api-key' do
	key = params["api_key"]
	key.strip!
	$vapi = Vapi.new(key)
	begin
    $org_id = $vapi.get_org_id
    $camera_data = $vapi.get_camera_data(page_size: 1, page_count: 1)
    $helix_event_types = $vapi.get_helix_event_types
	rescue
		error = "API key is invalid or lacks necessary permissions."
		message = 'Your API key should have Read-Only permissions to the Core Command endpoints, Read-Only permissions to Cameras endpoints, and Read/Write permissions to the Helix endpoints. For more information on generating an API key, see <a href="https://apidocs.verkada.com/reference/quick-start-guide" target="_blank">here</a>.'
		redirect "/error?error=#{error}&message=#{message}"
	end
	File.write('.env', "VERKADA_API_KEY=\"#{key}\"")
	process_config
	redirect '/'
end

get '/config/event-types' do
  erb :event_types_config_form
end

post '/config/event-types' do
	uploaded_file = load_event_types_config(params[:config_file][:tempfile].path)
	$event_config_message = check_event_config(uploaded_file)
	if $event_config_message == "Event types configuration checks passed."
		File.write('event_types_config.csv', params[:config_file][:tempfile].read)
		process_config
		redirect '/'
	else
		message = "For more information on the event types configuration file, see <a href='/help/event-types' target='_blank'>here</a>."
		redirect "/error?error=#{URI.encode_www_form_component($event_config_message)}&message=#{message}"
	end
end

get '/config/device-mappings' do
	erb :device_mappings_config_form
end

post '/config/device-mappings' do
	uploaded_file = import_csv(params[:config_file][:tempfile].path)
	$device_config_message = check_devices_config(uploaded_file)
	if $device_config_message == ["Device mappings configuration checks passed."]
		File.write('devices_config.csv', params[:config_file][:tempfile].read)
		process_config
		redirect '/'
	else
		message = "For more information on the device mappings configuration file, see <a href='/help/device-mappings' target='_blank'>here</a>."
		redirect "/error?error=#{URI.encode_www_form_component($device_config_message.join('<br>'))}&message=#{message}"
	end
end

get '/help/event-types' do
	content = File.read('views/help/event_types_config.html')
	content
end

get '/help/device-mappings' do
	content = File.read('views/help/device_mappings_config.html')
	content
end

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

	helix_event_attributes = {} # attributes for payload in create_helix_event request

	if $event_types_config.nil? || $event_types_config.empty? || $devices_config.nil? || $devices_config.empty?
		puts "Failed request: Server configuration is missing. Have you uploaded the necessary config files?"
		halt 400, { error: "Server configuration is missing. Have you uploaded the necessary config files?" }.to_json
	end

	event_types_by_id = $event_types_config.values.flatten.select {|i| i[:data_purpose] == "event type id"}

	# unique data that identifies the event type ("event type id" or "metric")
	event_type_id = event_types_by_id.find do |et|
		body.any? {|k, v| et.values.include?(k) && et.values.include?(v)}
	end
	if event_type_id.nil?
		event_types_by_metric = $event_types_config.values.flatten.select {|i| i[:data_purpose] == "metric"}
		event_type_id = event_types_by_metric.find do |et|
			body.any? {|k, _| et.values.include?(k)}
		end
	end
	if event_type_id.nil?
		puts "Could not identify even type based on data in body: #{body}"
		halt 500, { error: "Could not identify event type based on data in body"}.to_json
	end

	et_name = $event_types_config.find {|_key, arr| arr.include?(event_type_id)}&.first
	helix_event_type_config = $helix_event_types.select {|i| i[:name] == et_name} # remote helix event type config
	event_type_mapping = $event_types_config[et_name]
	device_id_key = event_type_mapping.select {|i| i[:data_purpose] == "device id"}&.first[:remote_key] # key with the value that maps to device id in devices_config

	body.keys.each do |key|
		config_row = $event_types_config[et_name].find{|hash| hash[:remote_key] == key}
		next if config_row[:data_type].nil? || config_row[:data_type].start_with?("time")
		helix_event_attributes[config_row[:helix_key]] = body[key]
	end

	unix_time = generate_event_timestamp(et_name, event_type_mapping, body)

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

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

puts 'passed config check'
exit

get '/' do
  "Under Construction"
end

post '/event' do
  body = JSON.parse(request.body.read)
end

post '/event/withtime' do
  body = JSON.parse(request.body.read)
end
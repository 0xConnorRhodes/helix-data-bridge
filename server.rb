# require 'sinatra'
require 'vapi'
require 'dotenv/load'
require 'csv'
require 'json'
require 'pry'

def load_config(file)
  config = []
  CSV.foreach(file, headers: true) do |row|
    config << row.to_h
  end
  config
end

api_key = ENV['VERKADA_API_KEY']

vapi = Vapi.new(api_key)

devices_config = load_config('devices_config.csv')
event_types_config = load_config('event_types_config.csv')

binding.pry

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
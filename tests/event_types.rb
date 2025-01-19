require 'vapi'
require 'dotenv'
require 'json'
require 'import_csv'
require_relative '../lib/load_event_types_config'
require_relative '../lib/check_config_files'
require_relative '../lib/check_api_key'
require_relative '../lib/create_event_types'
require 'pry'

Dotenv.load(File.expand_path('../../.env', __FILE__))

api_key = ENV['VERKADA_API_KEY']
$vapi = Vapi.new(api_key)

event_types_config = load_event_types_config('../event_types_config.csv')

data_purpose_check = check_data_purpose_field(event_types_config)
exit(1) unless data_purpose_check

event_types_config.transform_values! do |mappings|
  mappings
    .reject { |mapping| mapping[:data_purpose] == "event type id" }
    .map { |mapping| mapping.reject { |k, v| v.nil? || k == :data_purpose } }
end

event_types_config.each do |event|
	schema = event[1].each_with_object({}) do |mapping, schema|
		schema[mapping[:helix_key]] = mapping[:data_type]
	end

  begin
    $vapi.create_helix_event_type(
      name: event[0],
      schema: schema
    )
  rescue => e
    if e.message.include?("already exists for organization")
      puts "Event type \"#{event[0]}\" already exists"
    else
      raise e
    end
  end
end
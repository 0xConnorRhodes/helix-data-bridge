require 'vapi'
require 'dotenv'
Dotenv.load(File.join(__dir__, '..', '.env'))

vapi = Vapi.new(ENV['VERKADA_API_KEY'])

event_types = vapi.get_helix_event_types

event_types.each do |et|
  vapi.delete_helix_event_type(et[:event_type_uid])
end

[
  File.join(__dir__, '..', '.env'),
  File.join(__dir__, '..', 'event_types_config.csv'),
  File.join(__dir__, '..', 'devices_config.csv')
].each do |file|
  File.delete(file) if File.exist?(file)
end
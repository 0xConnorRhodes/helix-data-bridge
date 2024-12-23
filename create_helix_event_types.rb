require 'vapi'
require_relative 'lib/load_event_types_config'
require 'pry'

event_types_config = load_event_types_config('event_types_config.csv')

binding.pry
require 'httparty'
require 'json'
require 'pry'

hp = HTTParty
# bad json key
# motion_body = {
#   sensorName: "234",
#   datasource: "Motion"
# }

# nonexistent sensor
# motion_body = {
#   sensorName: "1234",
#   dataSource: "Motion"
# }

# nonexistent paired camera
motion_body = {
  sensorName: "234",
  dataSource: "Motion"
}

response = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'content-type' => 'application/json' },
  body: motion_body.to_json
)

puts "Motion response code: #{response.code}"
puts response

#binding.pry

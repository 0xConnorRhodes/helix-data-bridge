require 'httparty'
require 'json'
require 'pry'

hp = HTTParty

motion_body = {
  sensorName: "234",
  datasource: "Motion"
}

response = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'content-type' => 'application/json' },
  body: motion_body.to_json
)

puts "Motion response code: #{response.code}"

# binding.pry

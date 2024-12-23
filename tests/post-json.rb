require 'httparty'
require 'json'

hp = HTTParty

body = {
  sensorName: "123",
  dataSource: "Motion"
}

response = hp.post(
  'http://localhost:8080/event',
  headers: { 'Content-Type' => 'application/json' },
  body: body.to_json
)

puts "Response code: #{response.code}"
puts "Response body: #{response.body}"
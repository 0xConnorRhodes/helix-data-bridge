require 'httparty'
require 'json'

hp = HTTParty

body = {
  device: "Lab_Halo",
  temp: 65, 
}

response = hp.post(
  'http://127.0.0.1/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' },
  body: body.to_json
)

puts "response code: #{response.code}"
puts response

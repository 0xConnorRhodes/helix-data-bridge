require 'httparty'
require 'json'

hp = HTTParty

motion_body = {
  sensorName: "234",
  dataSource: "Motion"
}

motion_post = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' },
  body: motion_body.to_json
)

vape_body = {
  sensorName: "234",
  dataSource: "Vape"
}

vape_post = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' }, 
  body: vape_body.to_json
)

puts "Motion response code: #{motion_post.code}"
puts "Vape response code: #{vape_post.code}"

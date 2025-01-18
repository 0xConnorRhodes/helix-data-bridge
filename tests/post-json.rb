require 'httparty'
require 'json'

hp = HTTParty

motion_body = {
  sensorName: "234",
  dataSource: "Motion"
}

motion_post = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'content-type' => 'application/json' },
  body: motion_body.to_json
)

tamper_body = {
  sensorName: "234",
  dataSource: "Tamper"
}

tamper_post = hp.post(
  'http://localhost:8080/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' }, 
  body: tamper_body.to_json
)

puts "Motion response code: #{motion_post.code}"
puts "Tamper response code: #{tamper_post.code}"

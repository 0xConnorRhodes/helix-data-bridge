require 'httparty'
require 'json'

hp = HTTParty

time_body = {
  location: "Lab_Halo",
  event: "Tamper", 
  time: Time.now.strftime("%I:%M:%S %p")
}

time_post = hp.post(
  'http://192.168.86.97/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' },
  body: time_body.to_json
)

puts "Time event response code: #{time_post.code}"

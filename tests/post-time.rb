require 'httparty'
require 'json'

hp = HTTParty

time = Time.now.strftime("%I:%M:%S %p")

time_body = {
  location: "Lab_Halo",
  event: "Tamper", 
  time: time
}

time_post = hp.post(
  'http://127.0.0.1/event/by/keyid',
  headers: { 'Content-Type' => 'application/json' },
  body: time_body.to_json
)

puts "Time: #{time}"
puts "Time event response code: #{time_post.code}"

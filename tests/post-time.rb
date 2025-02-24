require 'httparty'
require 'json'

hp = HTTParty

# time = Time.now.strftime("%H:%M:%S")
# time = 1739145083000
# time = (Time.now.to_f - 60 * 60).round.strftime("%H:%M:%S")
# time = (Time.now.to_f - 60 * 60).round.strftime("%H:%M:%S")
time = Time.now.strftime("%H:%M:%S")

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

# puts "Time: #{time}"
puts "Time event response code: #{time_post.code}"

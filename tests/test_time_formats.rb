require 'httparty'
require 'json'
require 'time'

hp = HTTParty

location = "Test_Device"
event = "Tamper"

# Define the different time formats as pairs of [description, formatter lambda]
time_formats = [
  ["24-Hour Time (With Seconds)", ->(t) { t.strftime("%H:%M:%S") }],
  ["24-Hour Time (No Seconds)", ->(t) { t.strftime("%H:%M") }],
  ["12-Hour Time (With Seconds)", ->(t) { t.strftime("%I:%M:%S %p") }],
  ["12-Hour Time (No Seconds)", ->(t) { t.strftime("%I:%M %p") }],
  ["24-Hour Time (Leading Space for Single-Digit Hours)", ->(t) { t.strftime("%k:%M") }],
  ["12-Hour Time (Leading Space for Single-Digit Hours)", ->(t) { t.strftime("%l:%M %p") }],
  ["Unix Time as String", ->(t) { t.to_i.to_s }],
  ["Unix Time as Integer", ->(t) { t.to_i }]
]

# Iterate over each format and post the event using a fresh current time each iteration
time_formats.each do |description, formatter|
  current_time    = Time.now
  formatted_time  = formatter.call(current_time)

  time_body = {
    location: location,
    event: event,
    time: formatted_time
  }

  time_post = hp.post(
    'http://127.0.0.1/event/by/keyid',
    headers: { 'Content-Type' => 'application/json' },
    body: time_body.to_json
  )

  puts "#{description}: #{formatted_time}"
  puts "Response code: #{time_post.code}"
  puts "---------------"
end

def get_machine_timezone
  response = HTTParty.get("http://ip-api.com/json/")
  result = response.parsed_response
  result["timezone"]
end
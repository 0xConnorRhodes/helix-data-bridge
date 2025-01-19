def check_api_key
  env_file = File.join(File.dirname(__FILE__), '..', '.env')
  return false unless File.exist?(env_file)

  if File.exist?(env_file) && File.readlines(env_file).any? { |line| line.strip.start_with?('VERKADA_API_KEY=') }
    begin
      $org_id = $vapi.get_org_id
      $camera_data = $vapi.get_camera_data(page_size: 1, page_count: 1)
      $helix_event_types = $vapi.get_helix_event_types
      return true
    rescue => e
      puts "Failed request: API key is invalid. #{e.message}"
      return false
    end
  else
    return false
  end
end

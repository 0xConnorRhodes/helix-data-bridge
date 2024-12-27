def check_api_key
  env_file = File.join(File.dirname(__FILE__), '..', '.env')
  return false unless File.exist?(env_file)

  if File.exist?(env_file) && File.readlines(env_file).any? { |line| line.strip.start_with?('VERKADA_API_KEY=') }
    $org_id = $vapi.get_org_id
    return true
  else
    return false
  end
end

def create_event_types(config)
  data_purpose_check = check_data_purpose_field(config)
  exit(1) unless data_purpose_check
  
  # remove fields from config that are not used in the Helix schema
  stripped_config = config.transform_values do |mappings|
    mappings
      .reject { |mapping| mapping[:data_purpose] == "event type id" }
      .map { |mapping| mapping.reject { |k, v| v.nil? || k == :data_purpose } }
  end
  
  stripped_config.each do |event|
  	schema = event[1].each_with_object({}) do |mapping, schema|
  		schema[mapping[:helix_key]] = mapping[:data_type]
  	end
  
    begin
      $vapi.create_helix_event_type(
        name: event[0],
        schema: schema
      )
    rescue => e
      if e.message.include?("already exists for organization")
        puts "Event type \"#{event[0]}\" already exists"
      else
        raise e
      end
    end
  end
end
require 'import_csv'

def load_event_types_config(file)
  data = import_csv(file, symbolize_names: true)
  data = data.group_by {|row| row[:helix_event_type]}
    .transform_values { |rows| rows.map { 
    |row| row.reject { |k, _| k == :helix_event_type } } 
  }
  data
end
require 'csv'

def load_config(file)
  config = []
  CSV.foreach(file, headers: true) do |row|
    config << row.to_h
    .transform_keys { |key| key.downcase.gsub(' ', '_').to_sym }
  end
  config
end
require 'yaml'

def keys_to_sym src
  if src.is_a? Array
    src.map {|item| keys_to_sym item}
  elsif src.is_a? Hash
    Hash[src.map {|k, v| ["#{k}".to_sym, keys_to_sym(v)]}]
  else
    src
  end
end
def keys_to_str src
  if src.is_a? Array
    src.map {|item| keys_to_str item}
  elsif src.is_a? Hash
    Hash[src.map {|k, v| [k.to_s, keys_to_str(v)]}]
  else
    src
  end
end
def get_hash_file filename
  if File.exist?(filename)
    keys_to_sym YAML.load_file(filename)
  else
    nil
  end
end
def put_hash_file filename, props
  File.open(filename, 'w') do |f|
    f.write((keys_to_str props).to_yaml)
  end
end

class Utils
  def self.update_config(original, source)
    source.keys.each do |key|
      value = source[key]
      if original.include?(key)
        if value.is_a?(Hash) && original[key].is_a?(Hash)
          # hashes get merged recursively
          update_config(original[key], value)
        else
          # other values get overwritten
          original[key] = value
        end
      else
        # original doesn't contain this key yet, merging is easy
        original[key] = value
      end
    end
  end
end

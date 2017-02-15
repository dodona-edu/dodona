class Hash
  def recursive_update(other)
    other&.each do |key, value|
      if include?(key) && value.is_a?(Hash) && self[key].is_a?(Hash)
        # hashes get merged recursively
        self[key].recursive_update(value)
      else
        # other values get overwritten
        self[key] = value
      end
    end
    self
  end
end

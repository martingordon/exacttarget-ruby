class Hash
  def set_ns!(namespace, recurse = true)
    self.keys.each do |key|
      k_without_ns = key.to_s.split(":").last

      val = self.delete(key)
      val.set_ns!(namespace, recurse) if recurse and val.respond_to?(:set_ns!)

      self["#{namespace}:#{k_without_ns}"] = val
    end

    self
  end

  def camelize_keys!(recurse = true)
    self.keys.each do |key|
      val = self.delete(key)
      val.camelize_keys!(recurse) if recurse and val.respond_to?(:camelize_keys!)

      self[key.to_s.camelize] = val
    end

    self
  end
end

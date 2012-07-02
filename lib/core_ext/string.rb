class String
  unless self.new.respond_to? :pluralize
    # A very simple `pluralize` method that works for every object in the ExactTarget API.
    def pluralize
      self[-1] == "y" ? self[0...-1] + "ies" : self + "s"
    end
  end

  unless self.new.respond_to? :camelize
    def camelize
      split('_').map(&:capitalize).join
    end
  end
end

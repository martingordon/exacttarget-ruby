# Represents a filter.
# For more information, see the [ExactTarget documentation](http://docs.code.exacttarget.com/020_Web_Service_Guide/Objects/SimpleFilterPart).

module ET
  class Filter
    attr_accessor :property, :simple_operator, :value

    # Args can have 2 or 3 values: a property name, an operator (optional; defaults to equals), and a value.
    def initialize(*args)
      return if args.length == 0
      raise ArgumentError, "wrong number of arguments (#{args.length} for 2..3)" if args.length != 2 and args.length != 3

      self.property = args.first
      self.simple_operator = args.length == 2 ? "Equals" : args[1]
      self.value = args.last
    end

    def to_hash
      return nil if property.nil? and value.nil?

      hash = { property: property, simple_operator: simple_operator }

      if value.is_a? Date or value.is_a? Time
        hash[:date_value] = value
      else
        hash[:value] = value
      end
      hash
    end
  end
end

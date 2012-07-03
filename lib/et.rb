require "savon"

require "et/base"
require "et/delivery"
require "et/email"
require "et/email_send_definition"
require "et/filter"
require "et/list"
require "et/message"
require "et/subscriber"
require "et/version"

require "core_ext/array"
require "core_ext/hash"
require "core_ext/object"
require "core_ext/string"

Nori.parser = :nokogiri

module ET
  class Error < StandardError
    attr_accessor :code, :message

    def initialize(code, message)
      self.code = code
      self.message = message
    end

    def code=(new_code)
      @code = new_code.to_i
    end

    def to_s
      "#{code}: #{message}"
    end
  end

  class Errors
    attr_accessor :messages

    def initialize
      self.messages = {}
    end

    def add(code, message)
      messages[code] = message
    end

    def clear; messages.clear; end
    def length; messages.length; end
    def count; messages.count; end

    def to_a(include_codes = true)
      messages.map { |k,v| include_codes ? "#{v} (#{k})" : v }
    end
  end
end

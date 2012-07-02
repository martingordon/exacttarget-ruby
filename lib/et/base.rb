module ET
  class Base
    ENDPOINTS = {
      S1: 'https://webservice.exacttarget.com/Service.asmx',
      S4: 'https://webservice.s4.exacttarget.com/Service.asmx',
      S6: 'https://webservice.s6.exacttarget.com/Service.asmx'
    }

    # ET is stupid and the SOAPAction header doesn't always match the name of the top-level body tag. Here we map the
    # inconsistencies.
    SOAP_ACTION_HEADERS = {
      version_info_request_msg: "VersionInfo",
      retrieve_request_msg: "Retrieve"
    }

    attr_accessor :id, :errors

    @@username = nil
    @@password = nil

    def self.username=(username)
      @api = nil
      @@username = username
    end

    def self.username
      @@username
    end

    def self.password=(password)
      @api = nil
      @@password = password
    end

    def self.password
      @@password
    end

    # Simple helper method to convert class name to downcased pluralized version (e.g., Field -> fields).
    def self.plural_class_name
      self.et_object_type.downcase.pluralize
    end

    # Method to return the ET object type (in case it differs from the class name).
    def self.et_object_type
      self.to_s.split("::").last
    end

    # The primary method used to interface with the SOAP API.
    # This method automatically adds the required session header and returns the actual response section of the SOAP response body.
    #
    # Pass in a block and assign a hash to soap.body with a structure appropriate to the method call.
    def self.request(method, &_block)
      resp = api.request(:wsdl, method.to_s.camelize) do
        http.headers["SOAPAction"] = SOAP_ACTION_HEADERS[method] if SOAP_ACTION_HEADERS.has_key?(method)
        evaluate(&_block) if _block # See Savon::Client#evaluate; necessary to preserve scope.
      end

      resp.body[method.to_s.gsub("request", "response").to_sym]
    end

    # Sets up the Savon SOAP client object (if necessary) and returns it.
    def self.api
      return @api unless @api.nil?

      @api = Savon::Client.new do
        wsdl.endpoint = ENDPOINTS[:S1]
        wsdl.namespace = "http://exacttarget.com/wsdl/partnerAPI"
      end
      @api.wsse.credentials(username, password)
      @api
    end

    # Finds objects matching the `filter` (an ET::Filter instance). Returns only the properties requested.
    # If subsequent pages of results are required, pass the previous request ID as the `continue_request` parameter.
    def self.find(properties, filter = nil, continue_request = nil)
      resp = request(:retrieve_request_msg) do
        body = {
          retrieve_request: { object_type: et_object_type }
        }

        body[:retrieve_request][:filter] = filter.to_hash if filter.present? and filter.to_hash.present?
        body[:retrieve_request][:continue_request] = continue_request if continue_request.present?
        body[:retrieve_request][:properties] = properties.map { |p| p.is_a?(Symbol) ? p.to_s.camelize : p }

        soap.body = body.camelize_keys!.set_ns!("wsdl")
      end

      { overall_status: resp[:overall_status], request_id: resp[:request_id], results: resp[:results].map { |hash| new(hash) } }
    end

    # Saves a collection of ET::Base objects.
    # Objects without IDs are considered new and are `create`d; objects with IDs are considered existing and are `update`d.
    def self.save(*objs)
      objs = objs.flatten
      api_key = objs.first.is_a?(String) ? objs.shift : self.api_key

      updates = []
      creates = []

      objs.each { |o| (o.id.present? ? updates : creates) << o }

      update(updates) if updates.count > 0
      create(creates) if creates.count > 0
      objs
    end

    # Tells the remote server to create the passed in collection of ET::Base objects.
    # The object should implement `to_hash` to return a hash in the format expected by the SOAP API.
    #
    # Returns the same collection of objects that was passed in. Objects whose creation succeeded will be assigned the
    # ID returned from ExactTarget.
    # The first element passed in can be a string containing the API key; if none passed, will fall back to the global key.
    def self.create(*objs)
      objs = objs.flatten
      api_key = objs.first.is_a?(String) ? objs.shift : self.api_key

      resp = request(:create) do
        soap.body = {
          plural_class_name => objs.map(&:to_hash)
        }
      end

      objs.each { |o| o.errors.clear }

      Array.wrap(resp[:return][:results]).each_with_index do |result, i|
        if result[:is_error]
          objs[i].errors.add(result[:error_code], result[:error_string])
        else
          objs[i].id = result[:id]
        end
      end

      objs
    end

    # Updates a collection of ET::Base objects. The objects should exist on the remote server.
    # The object should implement `to_hash` to return a hash in the format expected by the SOAP API.
    # The first element passed in can be a string containing the API key; if none passed, will fall back to the global key.
    def self.update(*objs)
      objs = objs.flatten
      api_key = objs.first.is_a?(String) ? objs.shift : self.api_key

      resp = request(:update) do
        soap.body = {
          plural_class_name => objs.map(&:to_hash)
        }
      end

      objs.each { |o| o.errors.clear }
      objs
    end

    # Destroys a collection of ET::Base objects on the remote server.
    #
    # Returns the same collection of objects that was passed in. Objects whose destruction succeeded will
    # have a nil ID.
    #
    # The first element passed in can be a string containing the API key; if none passed, will fall back to the global key.
    def self.destroy(*objs)
      objs = objs.flatten
      api_key = objs.first.is_a?(String) ? objs.shift : self.api_key

      resp = request(:delete) do
        soap.body = {
          plural_class_name => objs.map { |o| { id: o.id }}
        }
      end

      Array.wrap(resp[:return][:results]).each_with_index do |result, i|
        if result[:is_error]
          objs[i].errors.add(result[:error_code], result[:error_string])
        else
          objs[i].id = nil
        end
      end

      objs
    end

    # Accepts a hash whose keys should be setters on the object.
    def initialize(options = {})
      self.errors = Errors.new
      options.each { |k,v| send("#{k}=", v) if respond_to?("#{k}=") }
    end

    # `to_hash` should be overridden to provide a hash whose structure matches the structure expected by the API.
    def to_hash
      {}
    end

    # Convenience instance method that calls the class `request` method.
    def request(method, &block)
      self.class.request(method, self.api_key, false, &block)
    end

    def reload
      return if self.id.blank?

      # The block below is evaluated in a weird scope so we need to capture self as _self for use inside the block.
      _self = self

      resp = request(:read) do
        soap.body = { filter: { id: _self.id } }
      end

      resp[:return].each do |k, v|
        self.send("#{k}=", v) if self.respond_to? "#{k}="
      end

      nil
    end

    # Saves the object. If the object has an ID, it is updated. Otherwise, it is created.
    def save
      id.blank? ? create : update
    end

    # Creates the object. See `ET::Base.create` for more info.
    def create
      res = self.class.create(self.api_key, self)
      res.first
    end

    # Updates the object. See `ET::Base.update` for more info.
    def update
      self.class.update(self.api_key, self).first
    end

    # Destroys the object. See `ET::Base.destroy` for more info.
    def destroy
      self.class.destroy(self.api_key, self).first
    end
  end
end

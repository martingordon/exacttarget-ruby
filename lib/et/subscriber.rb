module ET
  class Subscriber < Base
    attr_accessor :email_address, :attributes

    def reload
      return false if self.email_address.blank?

      filter = ET::Filter.new
      filter.add_filter("EmailAddress", self.email_address)

      new_contact = self.class.find([], filter).first

      self.id = new_contact.id
      self.attributes = new_contact.attributes

      true
    end

    def save
      self.class.save(self)
    end

    def to_hash
      if id.present?
        { id: id, email_address: email_address, attributes: attributes.map { |k,v| { name: k, value: v }}}
      else
        { email_address: email_address, attributes: attributes.map { |k,v| { name: k, value: v }}}
      end
    end

    def set_attr(name, value)
      self.attributes[name] = value
    end

    def get_attr(name)
      self.attributes[name].try(:value)
    end

  end
end

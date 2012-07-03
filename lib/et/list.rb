module ET
  class List < Base
    attr_accessor :list_name, :category, :type, :description, :subscribers, :list_classification,
        :automated_email, :send_classification
    find_properties :id, :list_name, :category, :type, :description

    # Removes all subscribers from the given lists.
    def self.clear_lists(*lists)
      lists = lists.flatten

      resp = request(:update) do
        soap.body = {
          update_request: {
            list: lists.map { |l| { id: l.id, subscribers: [] } }
          }
        }
      end

      lists.each { |l| l.reload }

      resp[:overall_status] == "OK"
    end

    def initialize(options = {})
      super(options)
    end

    def add_to_list(*subscribers)
      begin
        add_to_list!(subscribers)
      rescue ET::Error => e
        false
      end
    end

    # Adds the given subscribers to this list.
    def add_to_list!(*subscribers)
      return false if !self.id.present?
      subscribers = subscribers.flatten

      # The block below is evaluated in a weird scope so we need to capture self as _self for use inside the block.
      _self = self

      resp = request(:update) do
        soap.body = {
          list: { id: _self.id, subscribers: subscribers.map { |s| { id: s.id } } }
        }
      end

      # TODO
      errors = Array.wrap(resp[:return][:results]).select { |r| r[:is_error] }
      errors.each do |error|
        raise ET::Error.new(error[:error_code], error[:error_string])
      end

      true
    end

    def to_hash
      hash = { list_name: list_name, description: description, type: type, subscribers: subscribers }
      hash[:id] = id if id.present?
      hash
    end
  end
end

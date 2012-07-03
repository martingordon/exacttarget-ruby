module ET
  class EmailSendDefinition < Base
    # From InteractionBaseObject
    attr_accessor :name, :description, :keyword

    # From InteractionDefinition
    attr_accessor :interaction_object_id

    attr_accessor :category_id, :send_classification, :sender_profile, :delivery_profile

    find_properties :name, :description, :category_id
  end
end

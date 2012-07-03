module ET
  class Email < Base
    attr_accessor :created_date, :email_type, :has_dynamic_subject_line, :html_body, :name, :partner_properties, :subject, :text_body
    find_properties :created_date, :email_type, :has_dynamic_subject_line, :html_body, :name, :subject, :text_body
  end
end

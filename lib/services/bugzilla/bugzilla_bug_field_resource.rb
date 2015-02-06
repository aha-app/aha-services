class BugzillaBugFieldResource < BugzillaResource

  DEFAULT_FIELDS = %w{version bug_severity rep_platform op_sys priority}

  def get_defaults products
    response = http_get bugzilla_url("field/bug")
    body = process_response response
    defaults = products.inject({}){|hash, product| hash[product] = {}; hash }
    fields = body.fields.select{|f| DEFAULT_FIELDS.include?(f.name) }
    fields.each do |field|
      values = field[:values].sort_by{|value| value[:sort_key] }
      # When the allowed values depend on the product we have to cycle all values
      if field.value_field == "product" then
        values.each do |value|
          # The visibility_values field contains products for which this value is allowed
          value.visibility_values.each do |product|
            next unless products.include?(product)
            defaults[product][field.name] = value.name
          end
        end
      else
        defaults.each{|product, default| default[field.name] = values.last.name }
      end
    end
    defaults
  end

end

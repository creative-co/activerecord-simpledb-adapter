class Aws::SdbInterface
  def put_attributes(domain_name, item_name, attributes, replace = false, expected_attributes = {})
    params = params_with_attributes(domain_name, item_name, attributes, replace, expected_attributes)
    link = generate_request("PutAttributes", params)
    request_info( link, QSdbSimpleParser.new )
  rescue Exception
    on_exception
  end

  def delete_attributes(domain_name, item_name, attributes = nil, expected_attributes = {})
    params = params_with_attributes(domain_name, item_name, attributes, false, expected_attributes)
    link = generate_request("DeleteAttributes", params)
    request_info( link, QSdbSimpleParser.new )
  rescue Exception
    on_exception
  end

  private
  def pack_expected_attributes(attributes) #:nodoc:
    {}.tap do |result|
      idx = 0
      attributes.each do |attribute, value|
        v = value.is_a?(Array) ? value.first : value
        result["Expected.#{idx}.Name"]  = attribute.to_s
        result["Expected.#{idx}.Value"] = ruby_to_sdb(v)
        idx += 1
      end
    end
  end

  def pack_attributes(attributes = {}, replace = false, key_prefix = "")
    {}.tap do |result|
      idx = 0
      if attributes
        attributes.each do |attribute, value|
          v = value.is_a?(Array) ? value.first : value
          result["#{key_prefix}Attribute.#{idx}.Replace"] = 'true' if replace
          result["#{key_prefix}Attribute.#{idx}.Name"] = attribute
          result["#{key_prefix}Attribute.#{idx}.Value"] = ruby_to_sdb(v)
          idx += 1
        end
      end
    end
  end

  def params_with_attributes(domain_name, item_name, attributes, replace, expected_attrubutes)
    {}.tap do |p|
      p['DomainName'] = domain_name
      p['ItemName'] = item_name
      p.merge!(pack_attributes(attributes, replace)).merge!(pack_expected_attributes(expected_attrubutes))
    end
  end
end

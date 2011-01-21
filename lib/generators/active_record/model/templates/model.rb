class <%= class_name %> < <%= parent_class_name.classify %>
  columns_definition do |c|
<% for attribute in attributes -%>
    c.<%= attribute.type %> :<%= attribute.name %>
<% end -%>
<% if options[:timestamps] %>
    c.timestamps
<% end -%>
  end
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
end

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  class_attr_index = html_tag.index 'class='

  if class_attr_index
    # insert the is-invalid class as first class in the class attribute
    # 7 is the length of string class="
    html_tag.insert class_attr_index+7, 'is-invalid '
  else
    # if there is no class attribute, create one
    html_tag.insert html_tag.index('>'), ' class="is-invalid"'
  end
end

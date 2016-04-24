class StandardFormBuilder < ActionView::Helpers::FormBuilder
  def hasPermission?(attr)
    @template.policy(object).permits_attribute?(attr)
  end
end

class StandardFormBuilder < ActionView::Helpers::FormBuilder
  def permission?(attr)
    @template.policy(object).permits_attribute?(attr)
  end
end

json.unanswered do
  json.array! @unanswered, partial: 'annotations/annotation', as: :annotation
end

json.in_progress do
  json.array! @in_progress, partial: 'annotations/annotation', as: :annotation
end

json.answered do
  json.array! @answered, partial: 'annotations/annotation', as: :annotation
end

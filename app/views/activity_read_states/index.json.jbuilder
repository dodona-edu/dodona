json.array!(@read_states) do |read_state|
  json.extract! read_state, :created_at, :id
  json.url submission_url(read_state, format: :json)
  if read_state.course.present?
    json.user course_member_url(read_state.course, read_state.user.id, format: :json)
  else
    json.user user_url(read_state.user.id, format: :json)
  end
  json.course course_url(read_state.course, format: :json) if read_state.course
end

ExceptionNotifier.add_notifier :event_logger, lambda { |e, _options|
  Event.create(event_type: :error, user: Current.user, message: e.message)
}

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |_name, start, finish, _id, payload|
  next if finish - start < 5.seconds
  next if (payload[:action] == 'hook') && (payload[:controller] == 'RepositoriesController')
  next if (payload[:action] == 'create') && (payload[:controller] == 'RepositoriesController')
  next if (payload[:action] == 'scoresheet') && (payload[:controller] == 'CoursesController')

  headers = payload.delete :headers
  ExceptionNotifier.notify_exception(
    SlowRequestException.new("A request took #{finish - start} seconds"),
    env: headers.env,
    data: payload
  )
end

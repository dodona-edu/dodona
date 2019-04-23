ExceptionNotifier.add_notifier :event_logger, ->(e, options) {
  Event.create(event_type: :error, user: Current.user, message: e.message)
}

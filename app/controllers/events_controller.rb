class EventsController < ApplicationController
  include HasFilter

  has_filter :event_type

  def index
    authorize Event
    @filters = filters(policy_scope(Event))
    @events = apply_scopes(policy_scope(Event)).paginate(page: parse_pagination_param(params[:page]))
    @title = I18n.t('events.index.title')
  end
end

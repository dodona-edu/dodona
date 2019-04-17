class EventsController < ApplicationController
  def index
    authorize Event
    @events = apply_scopes(policy_scope(Event)).paginate(page: parse_pagination_param(params[:page]))
    @title = I18n.t('events.index.title')
  end
end

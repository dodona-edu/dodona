class EventsController < ApplicationController

  has_scope :by_type, as: "type"

  def index
    authorize Event
    @events = apply_scopes(policy_scope(Event)).paginate(page: parse_pagination_param(params[:page]))
    @title = I18n.t('events.index.title')
  end
end

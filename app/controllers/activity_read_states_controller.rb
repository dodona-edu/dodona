class ActivityReadStatesController < ApplicationController
  include SeriesHelper

  before_action :set_activity_read_states, only: %i[index]

  def index; end

  def create
    authorize ActivityReadState
    args = permitted_attributes(ActivityReadState)
    args[:user_id] = current_user.id
    course = Course.find(args[:course_id]) if args[:course_id].present?
    args.delete[:course_id] if args[:course_id].present? && course.subscribed_members.exclude?(current_user)
    read_state = ActivityReadState.new args
    can_read = Pundit.policy!(current_user, read_state.activity).read?
    if can_read && read_state.save
      respond_to do |format|
        format.js { render 'activities/read', locals: { activity: read_state.activity, course: read_state.course, read_state: read_state, user: current_user } }
        format.json { head :ok }
      end
    else
      render json: { status: 'failed', errors: read_state.errors }, status: :unprocessable_entity
    end
  end
end

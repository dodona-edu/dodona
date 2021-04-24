class RightsRequestsController < ApplicationController
  before_action :set_rights_request, only: %i[approve reject]

  def index
    authorize RightsRequest
    @requests = policy_scope(RightsRequest.all)
    @title = I18n.t('rights_requests.index.title')
  end

  def new
    authorize RightsRequest
    @title = I18n.t('rights_requests.new.title')
    @rights_request = RightsRequest.new
  end

  def create
    authorize RightsRequest
    @rights_request = RightsRequest.new(permitted_attributes(RightsRequest).merge({ user: current_user }))

    respond_to do |format|
      if @rights_request.save
        format.html { redirect_to root_path, notice: 'Rights request was successfully created.' }
        format.json { render :show, status: :created, location: @rights_request }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rights_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    @rights_request.approve
    @requests = policy_scope(RightsRequest.all)
  end

  def reject
    @rights_request.reject
    @requests = policy_scope(RightsRequest.all)
  end

  private

  def set_rights_request
    @rights_request = RightsRequest.find(params[:id])
    authorize @rights_request
  end
end

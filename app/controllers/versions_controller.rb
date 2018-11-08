class VersionsController < ApplicationController
  before_action :set_version, only: [:show, :edit, :update, :destroy]

  def index
    authorize Version
    @versions = policy_scope(Version).paginate(page: params[:page])
  end

  # GET /versions/new
  def new
    authorize Version
    @version = Version.new
    @title = I18n.t('versions.new.title')
    @crumbs = [[I18n.t('versions.index.title'), versions_path], [I18n.t('versions.new.title'), '#']]
  end

  # GET /versions/1/edit
  def edit
    @title = @version.tag
    @crumbs = [[I18n.t('versions.index.title'), versions_path], [@version.tag, '#']]
  end

  # POST /versions
  # POST /versions.json
  def create
    authorize Version
    @version = Version.new(permitted_attributes(Version))

    respond_to do |format|
      if @version.save
        format.html {redirect_to versions_url, notice: I18n.t('controllers.created', model: Version.model_name.human)}
        format.json {render :show, status: :created, location: @version}
      else
        format.html {render :new}
        format.json {render json: @version.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /versions/1
  # PATCH/PUT /versions/1.json
  def update
    respond_to do |format|
      if @version.update(permitted_attributes(@version))
        format.html {redirect_to versions_url, notice: I18n.t('controllers.updated', model: Version.model_name.human)}
        format.json {render :show, status: :ok, location: @version}
      else
        format.html {render :edit}
        format.json {render json: @version.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /versions/1
  # DELETE /versions/1.json
  def destroy
    @version.destroy
    respond_to do |format|
      format.html {redirect_to versions_url, notice: I18n.t('controllers.destroyed', model: Version.model_name.human)}
      format.json {head :no_content}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_version
    @version = Version.find(params[:id])
    authorize(@version)
  end
end

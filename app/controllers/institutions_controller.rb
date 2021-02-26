class InstitutionsController < ApplicationController
  before_action :set_institution, only: %i[show edit update]

  has_scope :by_filter, as: 'filter' do |_controller, scope, value|
    scope.by_name(value)
  end

  def index
    authorize Institution
    @institutions = apply_scopes(Institution).all.order(generated_name: :desc, name: :asc)
                                             .includes(:courses, :users, :providers)
                                             .paginate(page: parse_pagination_param(params[:page]))
    @title = I18n.t('institutions.index.title')
  end

  def show
    @title = @institution.name
    @crumbs = [[I18n.t('institutions.index.title'), institutions_path], [@institution.name, '#']]
    @staff = User.where(institution: @institution, permission: %i[staff zeus]).order(last_name: :asc, first_name: :asc, email: :asc)
  end

  def edit
    @title = @institution.name
    @crumbs = [[I18n.t('institutions.index.title'), institutions_path], [@institution.name, institution_url(@institution)], [I18n.t('crumbs.edit'), '#']]
  end

  def update
    respond_to do |format|
      if @institution.update(permitted_attributes(@institution))
        format.html { redirect_to institutions_url, notice: I18n.t('controllers.updated', model: Institution.model_name.human) }
        format.json { render :show, status: :ok, location: @institution }
      else
        format.html { render :edit }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_institution
    @institution = Institution.find(params[:id])
    authorize @institution
  end
end

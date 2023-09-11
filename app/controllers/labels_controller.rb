class LabelsController < ApplicationController
  before_action :set_label, except: %i[index new create]

  has_scope :by_name, as: 'filter'

  def index
    authorize Label
    @labels = policy_scope(Label.all).merge(apply_scopes(Label))
    @title = I18n.t('labels.index.title')
    @crumbs = [[I18n.t('labels.index.title'), '#']]
  end

  def show
    @title = @label.name
    @crumbs = [[I18n.t('labels.index.title'), labels_path], [@label.name, '#']]
  end

  def new
    authorize Label
    @label = Label.new
    @title = I18n.t('labels.new.title')
    @crumbs = [[I18n.t('labels.index.title'), labels_path], [I18n.t('labels.new.title'), '#']]
  end

  def edit
    @title = @label.name
    @crumbs = [[I18n.t('labels.index.title'), labels_path], [@label.name, label_path(@label)], [I18n.t('crumbs.edit'), '#']]
  end

  def create
    authorize Label
    @label = Label.new(permitted_attributes(Label))

    respond_to do |format|
      if @label.save
        format.html { redirect_to @label, notice: I18n.t('controllers.created', model: Label.model_name.human) }
        format.json { render :show, status: :created, location: @label }
      else
        format.html { render :new }
        format.json { render json: @label.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @label.update(permitted_attributes(@label))
        format.html { redirect_to @label, notice: I18n.t('controllers.updated', model: Label.model_name.human) }
        format.json { render :show, status: :ok, location: @label }
      else
        format.html { render :edit }
        format.json { render json: @label.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @label.destroy
    respond_to do |format|
      format.html { redirect_to labels_url, notice: I18n.t('controllers.destroyed', model: Label.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  def set_label
    @label = Label.find(params[:id])
    authorize @label
  end
end

class ProgrammingLanguagesController < ApplicationController
  before_action :set_programming_language, only: %i[show edit update destroy]

  def index
    authorize ProgrammingLanguage
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @title = I18n.t('programming_languages.index.title')
    @crumbs = [[I18n.t('programming_languages.index.title'), '#']]
  end

  def show
    @title = @programming_language.name
    @crumbs = [[I18n.t('programming_languages.index.title'), programming_languages_path], [@programming_language.name, '#']]
  end

  def new
    @programming_language = ProgrammingLanguage.new
    @title = I18n.t('programming_languages.new.title')
    @crumbs = [[I18n.t('programming_languages.index.title'), programming_languages_path], [I18n.t('programming_languages.new.title'), '#']]
  end

  def edit
    @title = @programming_language.name
    @crumbs = [
      [I18n.t('programming_languages.index.title'), programming_languages_path],
      [@programming_language.name, programming_language_path(@programming_language)],
      [I18n.t('programming_languages.edit.title'), '#']
    ]
  end

  def create
    @programming_language = ProgrammingLanguage.new(permitted_attributes(ProgrammingLanguage))

    respond_to do |format|
      if @programming_language.save
        format.html { redirect_to @programming_language, notice: I18n.t('controllers.created', model: ProgrammingLanguage.model_name.human) }
        format.json { render :show, status: :created, location: @programming_language }
      else
        format.html { render :new }
        format.json { render json: @programming_language.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @programming_language.update(permitted_attributes(@programming_language))
        format.html { redirect_to @programming_language, notice: I18n.t('controllers.updated', model: ProgrammingLanguage.model_name.human) }
        format.json { render :show, status: :ok, location: @programming_language }
      else
        format.html { render :edit }
        format.json { render json: @programming_language.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @programming_language.destroy
    respond_to do |format|
      format.html { redirect_to programming_languages_url, notice: I18n.t('controllers.destroyed', model: ProgrammingLanguage.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  def set_programming_language
    @programming_language = ProgrammingLanguage.find(params[:id])
    authorize @programming_language
  end
end

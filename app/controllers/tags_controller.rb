class TagsController < ApplicationController
  before_action :set_tag, except: %i[index new create]

  def index
    authorize Tag
    @tags = policy_scope(Tag.all)
    @title = I18n.t('tags.index.title')
    @crumbs = [[I18n.t('tags.index.title'), "#"]]
  end

  def show
    @title = @tag.name
    @crumbs = [[I18n.t('tags.index.title'), tags_path], [@tag.name, "#"]]
  end

  def new
    authorize Tag
    @tag = Tag.new
    @title = I18n.t('tags.new.title')
    @crumbs = [[I18n.t('tags.index.title'), tags_path], [I18n.t('tags.new.title'), "#"]]
  end

  def edit
    @title = @tag.name
    @crumbs = [[I18n.t('tags.index.title'), tags_path], [@tag.name, tag_path(@tag)], [I18n.t('crumbs.edit'), '#']]
  end

  def create
    authorize Tag
    @tag = Tag.new(permitted_attributes(Tag))

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: I18n.t('controllers.created', model: Tag.model_name.human) }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @tag.update(permitted_attributes(@tag))
        format.html { redirect_to @tag, notice: I18n.t('controllers.updated', model: Tag.model_name.human) }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url, notice: I18n.t('controllers.destroyed', model: Tag.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
    authorize @tag
  end
end

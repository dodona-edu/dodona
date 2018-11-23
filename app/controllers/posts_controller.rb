class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    authorize Post
    @posts = policy_scope(Post).paginate(page: params[:page], per_page: 5)
    @crumbs = [[I18n.t('posts.index.title'), '#']]
  end

  def show
    @title = @post.title
    @crumbs = [[I18n.t('posts.index.title'), posts_path], [@post.title, '#']]
  end

  # GET /posts/new
  def new
    authorize Post
    @post = Post.new
    @title = I18n.t('posts.new.title')
    @crumbs = [[I18n.t('posts.index.title'), posts_path], [I18n.t('posts.new.title'), '#']]
  end

  # GET /posts/1/edit
  def edit
    @title = @post.title
    @crumbs = [[I18n.t('posts.index.title'), posts_path], [@post.title, post_path(@post)], [I18n.t('crumbs.edit'), '#']]
  end

  # POST /posts
  # POST /posts.json
  def create
    authorize Post
    @post = Post.new(permitted_attributes(Post))

    respond_to do |format|
      if @post.save
        format.html {redirect_to post_url(@post), notice: I18n.t('controllers.created', model: Post.model_name.human)}
        format.json {render :show, status: :created, location: @post}
      else
        format.html {render :new}
        format.json {render json: @post.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    attributes = permitted_attributes(@post)
    if attributes[:content_en].present?
      @post.content_en.embeds.detach
    end
    if attributes[:content_nl].present?
      @post.content_nl.embeds.detach
    end
    respond_to do |format|
      if @post.update(permitted_attributes(@post))
        format.html {redirect_to post_url(@post), notice: I18n.t('controllers.updated', model: Post.model_name.human)}
        format.json {render :show, status: :ok, location: @post}
      else
        format.html {render :edit}
        format.json {render json: @post.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html {redirect_to posts_url, notice: I18n.t('controllers.destroyed', model: Post.model_name.human)}
      format.json {head :no_content}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params[:id])
    authorize(@post)
  end
end

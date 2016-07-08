class CoursesController < ApplicationController
  before_action :set_course, only: [:show, :edit, :update, :destroy, :subscribe, :subscribe_with_secret]

  # GET /courses
  # GET /courses.json
  def index
    authorize Course
    @courses = Course.all
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
  end

  # GET /courses/new
  def new
    authorize Course
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit
  end

  # POST /courses
  # POST /courses.json
  def create
    authorize Course
    @course = Course.new(permitted_attributes(Course))

    respond_to do |format|
      if @course.save
        @course.users << current_user
        format.html { redirect_to @course, notice: 'Course was successfully created.' }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { render :new }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /courses/1
  # PATCH/PUT /courses/1.json
  def update
    respond_to do |format|
      if @course.update(permitted_attributes(Course))
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { render :show, status: :ok, location: @course }
      else
        format.html { render :edit }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.json
  def destroy
    @course.destroy
    respond_to do |format|
      format.html { redirect_to courses_url, notice: 'Course was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def subscribe
    membership = CourseMembership.new(course: @course, user: current_user)
    respond_to do |format|
      if membership.save
        format.html { redirect_to @course, notice: 'Subscribed successfully' }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { redirect_to @course, alert: 'Subscription failed' }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def subscribe_with_secret
    if !current_user
      redirect_to(@course, notice: 'You need to be logged in to subscribe')
    elsif params[:secret] != @course.secret
      redirect_to(@course, alert: "The key didn't match")
    elsif current_user.member_of?(@course)
      redirect_to(@course)
    else
      subscribe
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find(params[:id])
    authorize @course
  end
end

class PagesController < ApplicationController
  content_security_policy only: %i[contact create_contact] do |policy|
    policy.script_src(*(%w[https://hcaptcha.com https://*.hcaptcha.com] + policy.script_src))
    policy.style_src(*(%w[https://hcaptcha.com https://*.hcaptcha.com] + policy.style_src))
    policy.connect_src(*(%w[https://hcaptcha.com https://*.hcaptcha.com] + policy.connect_src))
    policy.frame_src('https://hcaptcha.com', 'https://*.hcaptcha.com')
  end

  def home
    @title = 'Home'
    @crumbs = []
    if current_user
      @recent_exercises = current_user.recent_exercises(5)
      ActivityStatus.add_status_for_user_and_activities(current_user, @recent_exercises, [last_submission: [:course]])

      course_memberships = current_user.course_memberships.includes(course: %i[institution series]).select(&:subscribed?)
      @subscribed_courses = course_memberships.map(&:course)
      @favorite_courses = course_memberships.select(&:favorite).map(&:course)
      @grouped_courses = @subscribed_courses.sort_by(&:year).reverse.group_by(&:year)
      @homepage_series = @subscribed_courses.map { |c| c.homepage_series(0) }.flatten.sort_by(&:deadline)

      latest_submission = current_user.submissions.first
      if latest_submission.nil?
        @jump_back_in = nil
      elsif latest_submission.accepted?
        if latest_submission.series.nil?
          @jump_back_in = latest_submission.course
        else
          next_activity = latest_submission.series.next_activity(latest_submission.exercise)
          if next_activity.nil?
            next_series = latest_submission.series.next
            if next_series.nil?
              @jump_back_in = latest_submission.course
            else
              @jump_back_in = next_series
            end
          else
            @jump_back_in = next_activity
          end
        end
        @jump_back_in = latest_submission.exercise
      else
        @jump_back_in = latest_submission
      end
    else
      set_metrics
      respond_to do |format|
        format.html { render :static_home }
        format.json { render partial: 'static_home' }
      end
    end
  end

  def institution_not_supported; end

  def about
    set_metrics
  end

  def data; end

  def privacy; end

  def support
    set_metrics
  end

  def toggle_demo_mode
    authorize :pages
    session[:demo] = !Current.demo_mode
  end

  def toggle_dark_mode
    authorize :pages
    session[:dark] = params[:dark].nil? ? !session[:dark] : ActiveModel::Type::Boolean.new.cast(params[:dark])
  end

  def contact
    @contact_form = ContactForm.new
    @title = I18n.t('pages.contact.title')
  end

  def create_contact
    if /xevil/i =~ contact_params[:message]
      redirect_to root_path
      return
    end

    @contact_form = ContactForm.new(contact_params)
    @contact_form.request = request # Allows us to also send ip
    @contact_form.validate
    if verify_hcaptcha(model: @contact_form, message: t('.captcha_failed')) && @contact_form.deliver
      redirect_to root_path, notice: t('.mail_sent')
    else
      flash.now[:error] = @contact_form.errors.full_messages.to_sentence
      render :contact
    end
  end

  def profile
    authorize :pages
    redirect_to user_path(current_user)
  end

  private

  def contact_params
    params.require(:contact_form)
          .merge(dodona_user: current_user&.inspect)
  end

  def set_metrics
    @total_submissions = Submission.order(id: :desc).limit(1).pick(:id)
    @total_users = User.order(id: :desc).limit(1).pick(:id)
    @total_activities = Activity.count
    @total_schools = Institution.order(id: :desc).limit(1).pick(:id)
  end
end

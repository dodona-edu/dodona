class PagesController < ApplicationController
  def home
    @title = 'Home'
    @user = current_user
  end

  def sign_in_page
    if params[:idp].present?
      session[:current_idp] = params[:idp]
      redirect_to new_user_session_url(idp: params[:idp])
    end
    @institutions = Institution.all
  end

  def institution_not_supported; end

  def about; end

  def contact
    @contact_form = ContactForm.new
  end

  def create_contact
    @contact_form = ContactForm.new(contact_params)
    @contact_form.request = request # Allows us to also send ip
    @contact_form.validate
    if verify_recaptcha(model: @contact_form,  message: t('.captcha_failed')) && @contact_form.deliver
      redirect_to root_path, notice: t('.mail_sent')
    else
      flash[:error] = @contact_form.errors.full_messages.to_sentence
      render :contact
    end
  end

  private

  def contact_params
    params.require(:contact_form)
      .merge(dodona_user: current_user&.inspect)
  end
end

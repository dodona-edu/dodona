class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[csp_report]
  skip_before_action :redirect_to_default_host, only: %i[csp_report]

  content_security_policy only: %i[contact] do |policy|
    policy.script_src(*(%w[https://www.recaptcha.net https://www.gstatic.com
                           https://www.google.com] + policy.script_src))
    policy.frame_src 'https://www.google.com'
  end

  def home
    @title = 'Home'
    @crumbs = []
  end

  def sign_in_page
    if params[:idp].present?
      session[:current_idp] = params[:idp]
      redirect_to new_user_session_url(idp: params[:idp])
    end
    @institutions = Institution.all
    @title = I18n.t('pages.sign_in_page.sign_in')
  end

  def institution_not_supported; end

  def about; end

  def data; end

  def privacy; end

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
    @contact_form = ContactForm.new(contact_params)
    @contact_form.request = request # Allows us to also send ip
    @contact_form.validate
    if verify_recaptcha(model: @contact_form, message: t('.captcha_failed')) && @contact_form.deliver
      redirect_to root_path, notice: t('.mail_sent')
    else
      flash[:error] = @contact_form.errors.full_messages.to_sentence
      render :contact
    end
  end

  def csp_report
    if request.content_type == 'application/csp-report'
      raw_report = request.raw_post
      begin
        report = JSON.parse(raw_report)['csp-report']
        message = "CSP Violation Report: blocked '#{report['blocked-uri']}' on page '#{report['document-uri']}' which violated '#{report['violated-directive']}'"
      rescue JSON::ParserError, NoMethodError => e
        report = {
          'error': 'could not parse CSP report',
          'raw_report': raw_report,
          'error_message': e.message
        }
        message = "Could not parse CSP Violation Report: '#{raw_report}'"
      end
      ExceptionNotifier.notify_exception(
        Exception.new(message.truncate(254)),
        env: request.env,
        data: {
          report: report
        }
      )
    end
    head :ok
  end

  private

  def contact_params
    params.require(:contact_form)
          .merge(dodona_user: current_user&.inspect)
  end
end

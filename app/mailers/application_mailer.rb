class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.dodona_email
  layout 'mailer'

  def login_rejected
    @authinfo = params[:authinfo]
    uid = @authinfo['uid']
    provider = @authinfo['provider']
    email = @authinfo['info']['email']
    institution = @authinfo['info']['institution']

    mail to: Rails.application.config.dodona_email,
         subject: "Login op Dodona geweigerd voor #{uid} (#{email}) "\
                  "via #{provider} van een onbekende instelling (#{institution})",
         content_type: 'text/plain',
         body: "Authenticatie-info:\n#{@authinfo.pretty_inspect}\n"
  end
end

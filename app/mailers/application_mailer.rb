class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.dodona_email
  layout 'mailer'

  def institution_created
    @authinfo = params[:authinfo]
    uid = @authinfo['uid']
    provider = @authinfo['provider']
    email = @authinfo['info']['email']
    institution = @authinfo['info']['institution']

    mail to: Rails.application.config.dodona_email,
         subject: "Onderwijsinstelling aangemaakt voor #{uid} (#{email}) "\
                  "via #{provider} (#{institution})",
         content_type: 'text/plain',
         body: "Authenticatie-info:\n#{@authinfo.pretty_inspect}\n"
  end

  def institution_creation_failed
    @authinfo = params[:authinfo]
    @errors = params[:errors]
    uid = @authinfo['uid']
    provider = @authinfo['provider']
    email = @authinfo['info']['email']
    institution = @authinfo['info']['institution']

    mail to: Rails.application.config.dodona_email,
         subject: "Niet gelukt om onderwijsinstelling aan te maken voor #{uid} (#{email}) "\
                  "via #{provider} (#{institution})",
         content_type: 'text/plain',
         body: "Authenticatie-info:\n#{@authinfo.pretty_inspect}\nErrors:\n#{@errors.pretty_inspect}"
  end
end

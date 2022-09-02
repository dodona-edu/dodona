module PagesHelper
  def institution_logo(logo)
    # if we use an image that doesn't exist, we get a hard error
    if File.file?("app/assets/images/idp/#{logo}")
      "idp/#{logo}"
    else
      'idp/fallback.png'
    end
  end
end

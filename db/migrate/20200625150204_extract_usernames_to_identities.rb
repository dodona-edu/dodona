class ExtractUsernamesToIdentities < ActiveRecord::Migration[6.0]
  def change
    User.find_each do |user|
      if user.institution.present?
        Identity.create provider: user.institution.providers.first,
                        identifier: user.username,
                        user: user
      end
    end
  end
end

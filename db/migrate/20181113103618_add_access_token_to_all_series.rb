class AddAccessTokenToAllSeries < ActiveRecord::Migration[5.2]
  def change
    Series.find_each do |s|
      if s.access_token.blank?
        s.generate_access_token
      end
    end
  end
end

class AddInstitutionToUsers < ActiveRecord::Migration[5.1]
  def change
    add_reference :users, :institution, foreign_key: true
  end
end

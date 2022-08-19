class ChangeProviderInstitutionId < ActiveRecord::Migration[7.0]
  def change
    change_column_null :providers, :institution_id, true
  end
end

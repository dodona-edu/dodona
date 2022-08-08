class AddAnonymousToEvaluation < ActiveRecord::Migration[7.0]
  def change
    add_column :evaluations, :anonymous, :boolean, null: false, default: false
  end
end

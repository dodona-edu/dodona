class InternationalisePostTitle < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :title_en, :string
    add_column :posts, :title_nl, :string

    Post.all.find_each do |p|
      p.update(title_en: p.title, title_nl: p.title)
    end

    change_column :posts, :title_en, :string, null: false
    change_column :posts, :title_nl, :string, null: false
    remove_index :posts, [:title, :release]
    remove_column :posts, :title
  end
end

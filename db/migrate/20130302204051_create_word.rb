class CreateWord < ActiveRecord::Migration
  def change
    create_table :words do |t|
      t.string :word, :accent_word
      t.text :description
    end
  end
end

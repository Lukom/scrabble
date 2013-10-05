class CreateSuaWordLinks < ActiveRecord::Migration
  def change
    create_table :sua_words do |t|
      t.string :word
      t.boolean :crawled
      t.text :content

      t.timestamps
    end
  end
end

class AddSuaWordRelated < ActiveRecord::Migration
  def change
    add_column :sua_words, :linked_word, :string
    add_column :sua_words, :linked_word_id, :integer
    add_column :sua_words, :empty_word, :boolean
  end
end

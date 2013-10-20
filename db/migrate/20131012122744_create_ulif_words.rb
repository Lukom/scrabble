class CreateUlifWords < ActiveRecord::Migration
  def change
    create_table :ulif_words do |t|
      t.string :word
      t.boolean :crawled
      t.text :content
      t.integer :no
      t.boolean :has_syn
      t.boolean :has_phras

      t.timestamps
    end
  end
end

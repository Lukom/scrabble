class AddHasGToWord < ActiveRecord::Migration
  def change
    add_column :words, :has_g, :boolean
  end
end

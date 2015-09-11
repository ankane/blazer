class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :blazer_queries do |t|
      t.references :creator
      t.string :name
      t.text :description
      t.text :statement
      t.timestamps
    end

    create_table :blazer_audits do |t|
      t.references :user
      t.references :query
      t.text :statement
      t.timestamp :created_at
    end
  end
end

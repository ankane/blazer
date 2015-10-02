class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :blazer_queries do |t|
      t.references :creator
      t.string :name
      t.text :description
      t.text :statement
      t.string :data_source
      t.timestamps
    end

    create_table :blazer_audits do |t|
      t.references :user
      t.references :query
      t.text :statement
      t.string :data_source
      t.timestamp :created_at
    end

    create_table :blazer_dashboards do |t|
      t.text :name
      t.timestamps
    end

    create_table :blazer_dashboard_queries do |t|
      t.references :dashboard
      t.references :query
      t.integer :position
      t.timestamps
    end

    create_table :blazer_checks do |t|
      t.references :blazer_query
      t.string :state
      t.text :emails
      t.timestamps
    end
  end
end

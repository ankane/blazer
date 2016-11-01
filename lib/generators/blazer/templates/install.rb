class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :blazer_queries do |t|
      t.references :creator
      t.string :name
      t.text :description
      t.text :statement
      t.string :data_source
      t.string :status
      t.boolean :verified, default: false
      t.timestamps null: false
    end

    create_table :blazer_audits do |t|
      t.references :user
      t.references :query
      t.text :statement
      t.string :data_source
      t.timestamp :created_at
    end

    create_table :blazer_dashboards do |t|
      t.references :creator
      t.text :name
      t.timestamps null: false
    end

    create_table :blazer_dashboard_queries do |t|
      t.references :dashboard
      t.references :query
      t.integer :position
      t.timestamps null: false
    end

    create_table :blazer_checks do |t|
      t.references :creator
      t.references :query
      t.string :state
      t.string :schedule
      t.text :emails
      t.string :check_type
      t.boolean :notify_on_error, default: true
      t.boolean :notify_on_pass, default: true
      t.text :message
      t.timestamp :last_run_at
      t.timestamps null: false
    end
  end
end

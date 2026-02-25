class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.string :hubspot_id
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :company_name
      t.string :job_title
      t.string :lifecycle_stage

      t.timestamps
    end
    add_index :contacts, :hubspot_id, unique: true
    add_index :contacts, :email
  end
end

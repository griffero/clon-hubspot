class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :hubspot_id
      t.string :name
      t.string :domain
      t.string :industry
      t.string :phone
      t.string :city
      t.string :country
      t.integer :number_of_employees
      t.decimal :annual_revenue

      t.timestamps
    end
    add_index :companies, :hubspot_id, unique: true
    add_index :companies, :domain
  end
end

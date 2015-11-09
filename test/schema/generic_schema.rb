ActiveRecord::Schema.define do
  create_table :groups, :force => true do |t|
    t.column :order_col, :string
    t.timestamps null: true
  end
  create_table :test_tables, :force => true do |t|
    t.column :author_name, :string
    t.integer :group_id
    t.timestamps null: true
  end
  create_table :items, :force => true do |t|
    t.column :itemno, :string
    t.column :sizen, :integer
    t.column :company, :integer
    t.timestamps null: true
  end
  create_table :assemblies, :force => true do |t|
    t.string :name
    t.timestamps null: true
  end

  create_table :parts, :force => true do |t|
    t.string :part_number
    t.timestamps null: true
  end

  create_table :assemblies_parts, :force => true, id: false do |t|
    t.belongs_to :assembly
    t.belongs_to :part
  end
  #add_foreign_key :test_tables, :groups
end

ActiveRecord::Schema.define do
  create_table :groups, :force => true do |t|
    t.column :order, :string
    t.timestamps null: true
  end
  create_table :test_tables, :force=>true do |t|
    t.column :author_name, :string
    t.timestamps null: true
  end
end

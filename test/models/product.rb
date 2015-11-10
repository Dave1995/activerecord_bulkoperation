class Product < ActiveRecord::Base
  has_and_belongs_to_many :related_products, 
    class_name: "Product",
    association_primary_key: "product_id", 
    join_table: "products_related_products",
    association_foreign_key: "related_product_id"
end
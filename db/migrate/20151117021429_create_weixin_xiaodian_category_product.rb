class CreateWeixinXiaodianCategoryProduct < ActiveRecord::Migration
  def change
    create_table :weixin_xiaodian_category_products, id: false do |t|
      t.integer :weixin_xiaodian_category_id
      t.integer :weixin_xiaodian_product_id
    end
  end
end

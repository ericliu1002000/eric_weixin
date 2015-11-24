class CreateWeixinXiaodianProductSkuDetail < ActiveRecord::Migration
  def change
    create_table :weixin_xiaodian_product_sku_details do |t|
      t.integer :weixin_xiaodian_product_id
      t.string :sku_id
      t.integer :price
      t.string :icon_url
      t.integer :quantity
      t.string :product_code
      t.integer :ori_price
      t.integer :weixin_xiaodian_sku_name_id
      t.integer :weixin_xiaodian_sku_value_id
    end
  end
end

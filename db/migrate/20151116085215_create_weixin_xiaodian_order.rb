class CreateWeixinXiaodianOrder < ActiveRecord::Migration
  def change
    create_table :weixin_xiaodian_orders do |t|
      t.integer :weixin_user_id
      t.string :order_id
      t.integer :weixin_product_id
      t.string :sku_info, :limit => 1000
      t.integer :order_status
      t.integer :order_total_price
      t.integer :order_create_time
      t.integer :order_express_price
      t.string :buyer_nick
      t.string :receiver_name
      t.string :receiver_province
      t.string :receiver_city
      t.string :receiver_zone
      t.string :receiver_address
      t.string :receiver_mobile
      t.string :receiver_phone
      t.string :product_name
      t.integer :product_price
      t.string :product_sku
      t.integer :product_count
      t.string :product_img
      t.string :delivery_id
      t.string :delivery_company
      t.string :trans_id
      t.integer :weixin_public_account_id


    end
  end
end

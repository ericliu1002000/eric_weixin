class CreateWeixinXiaodianSkuValue < ActiveRecord::Migration
  def change
    create_table :weixin_xiaodian_sku_values do |t|
      t.integer :weixin_xiaodian_sku_name_id
      t.string :name
      t.string :wx_value_id
    end
  end
end

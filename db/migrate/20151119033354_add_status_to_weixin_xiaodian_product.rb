class AddStatusToWeixinXiaodianProduct < ActiveRecord::Migration
  def change
    add_column :weixin_xiaodian_products,  :status, :integer
    add_column :weixin_xiaodian_products,  :weixin_public_account_id, :integer
    add_column :weixin_xiaodian_products,  :delivery_type, :integer
  end
end

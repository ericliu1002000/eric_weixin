class AddSigninToXiaodianOrder < ActiveRecord::Migration
  def change
    remove_column :weixin_xiaodian_orders, :weixin_user_id
    add_column :weixin_xiaodian_orders, :sign_in_flg, :boolean, :default => false
    add_column :weixin_xiaodian_orders, :sign_in_time, :datetime
    add_column :weixin_xiaodian_orders, :sign_in_timeout_time, :datetime
    add_column :weixin_xiaodian_orders, :sign_in_type, :string  #签收类型, 自主签收or超时签收
  end
end

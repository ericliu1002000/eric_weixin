class AddUnionidToWeixinUsers < ActiveRecord::Migration
  def change
    add_column :weixin_users, :unionid, :string
  end
end

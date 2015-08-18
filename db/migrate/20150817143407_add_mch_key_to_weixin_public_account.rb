class AddMchKeyToWeixinPublicAccount < ActiveRecord::Migration
  def change
    add_column :weixin_public_accounts, :mch_key, :string
  end
end

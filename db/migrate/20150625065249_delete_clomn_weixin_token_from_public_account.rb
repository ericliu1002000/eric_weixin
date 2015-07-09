class DeleteClomnWeixinTokenFromPublicAccount < ActiveRecord::Migration
  def change
    remove_column :weixin_public_accounts, :weixin_token
  end
end

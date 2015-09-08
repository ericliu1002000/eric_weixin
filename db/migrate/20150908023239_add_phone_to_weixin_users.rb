class AddPhoneToWeixinUsers < ActiveRecord::Migration
  def change
    add_column :weixin_users, :phone, :string
  end
end

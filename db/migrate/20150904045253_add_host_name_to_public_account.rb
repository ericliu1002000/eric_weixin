class AddHostNameToPublicAccount < ActiveRecord::Migration
  def change
    add_column :weixin_public_accounts, :host_name_with_schema, :string
  end
end

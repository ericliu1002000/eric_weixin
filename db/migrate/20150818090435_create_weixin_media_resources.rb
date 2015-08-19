class CreateWeixinMediaResources < ActiveRecord::Migration
  def change
    create_table :weixin_media_resources do |t|
      t.string :tags
      t.string :category_name
      t.string :local_link
      t.string :wechat_link
      t.string :media_id
      t.integer :public_account_id
      t.timestamps
    end
  end
end

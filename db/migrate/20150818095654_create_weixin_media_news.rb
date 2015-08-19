class CreateWeixinMediaNews < ActiveRecord::Migration
  def change
    create_table :weixin_media_news do |t|
      t.datetime :planned_send_time
      t.datetime :send_time
      t.string :user_group_name
      t.string :media_id
      t.datetime :upload_time
      t.boolean :is_to_all
      t.integer :sent_count
      t.integer :total_count
      t.integer :filter_count
      t.integer :status
      t.integer :public_account_id
      t.timestamps
    end
  end
end

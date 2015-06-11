class CreateWeixinReportNewsData < ActiveRecord::Migration
  def change
    create_table :weixin_report_news_data do |t|
      t.date :ref_date
      t.string :ref_hour
      t.date :stat_date
      t.string :msgid
      t.string :title
      t.integer :int_page_read_user
      t.integer :int_page_read_count
      t.integer :ori_page_read_user
      t.integer :ori_page_read_count
      t.integer :share_scene
      t.integer :share_user
      t.integer :share_count
      t.integer :add_to_fav_user
      t.integer :add_to_fav_count
      t.integer :target_user
      t.integer :weixin_public_account_id

      t.timestamps
    end
  end
end

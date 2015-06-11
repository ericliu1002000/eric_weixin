class CreateWeixinReportMsgData < ActiveRecord::Migration
  def change
    create_table :weixin_report_msg_data do |t|
      t.date :ref_date
      t.string :ref_hour
      t.integer :msg_type
      t.integer :msg_user
      t.integer :msg_count
      t.integer :count_interval
      t.integer :int_page_read_count
      t.integer :ori_page_read_user
      t.integer :weixin_public_account_id

      t.timestamps
    end
  end
end

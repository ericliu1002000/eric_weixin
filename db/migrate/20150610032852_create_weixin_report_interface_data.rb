class CreateWeixinReportInterfaceData < ActiveRecord::Migration
  def change
    create_table :weixin_report_interface_data do |t|
      t.date :ref_date
      t.integer :ref_hour
      t.integer :callback_count
      t.integer :fail_count
      t.integer :total_time_cost
      t.integer :max_time_cost
      t.integer :weixin_public_account_id

      t.timestamps
    end
  end
end

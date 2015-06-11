class AddUserSourceToWeixinReportMsgData < ActiveRecord::Migration
  def change
    add_column :weixin_report_msg_data, :user_source, :integer
  end
end

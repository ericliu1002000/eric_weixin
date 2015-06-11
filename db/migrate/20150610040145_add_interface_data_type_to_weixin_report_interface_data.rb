class AddInterfaceDataTypeToWeixinReportInterfaceData < ActiveRecord::Migration
  def change
    add_column :weixin_report_interface_data, :interface_data_type, :string
  end
end

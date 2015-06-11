class AddNewsDataTypeToWeixinReportNewsData < ActiveRecord::Migration
  def change
    add_column :weixin_report_news_data, :news_data_type, :string
  end
end

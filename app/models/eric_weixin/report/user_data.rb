class EricWeixin::Report::UserData < ActiveRecord::Base
  self.table_name = 'weixin_report_user_data'

  USER_DATA_TYPE = ['summary', 'cumulate']

  def self.create_one options
    self.transcation do
      options = get_arguments_options options, [:cancel_user, :new_user, :ref_date, :user_source, :weixin_public_account_id, :user_data_type]
      user_data = self.new options
      user_data.save!
      user_data.reload
      user_data
    end
  end

  def self.exist_one options
    options = get_arguments_options options, [:cancel_user, :new_user, :ref_date, :user_source, :weixin_public_account_id, :user_data_type]
    self.where( options ).count >= 1
  end

  # 特别注意，时间跨度都是7
  def self.create_some begin_date, end_date
    self.transcation do
      options = {
          :begin_date => begin_date,
          :end_date => end_date
      }
      user_summary = ::EricWeixin::AnalyzeData.get_user_summary options
      list_summary = user_summary["list"]
      list_summary.each do |s|
        s = s.merge(user_data_type: 'summary')
        self.create_one s unless self.exist_one s
      end unless list_summary.blank?
      user_cumulate = ::EricWeixin::AnalyzeData.get_user_cumulate options
      list_cumulate = user_cumulate["list"]
      list_cumulate.each do |s|
        s = s.merge(user_data_type: 'cumulate')
        self.create_one s unless self.exist_one s
      end unless list_cumulate.blank?
    end
  end
end
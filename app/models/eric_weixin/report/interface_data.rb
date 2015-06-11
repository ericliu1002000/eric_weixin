class EricWeixin::Report::InterfaceData < ActiveRecord::Base
  self.table_name = 'weixin_report_interface_data'

  INTERFACE_DATA_TYPE = ['summary', 'summary_hour']

  validates_presence_of :interface_data_type, message: "数据类型不可以为空。"
  validates_inclusion_of :interface_data_type, in: INTERFACE_DATA_TYPE, message: "不正确的数据类型，只能为summary、summary_hour其中一个。"

  # 自动去微信服务器拉取当日之前的统计模块的接口数据.
  # ===参数说明
  # * weixin_public_account_id # 微信公众号ID
  # ===调用实例
  # ::EricWeixin::Report::InterfaceData.auto_execute_get_and_save_data_from_weixin 1
  def self.auto_execute_get_and_save_data_from_weixin weixin_public_account_id
    self.transaction do
      yesterday = (Time.now - 1.day).to_date.to_s
      # 取当天的前一天数据
      get_and_save_interface_summary yesterday, yesterday, weixin_public_account_id
      get_and_save_interface_summary_hour yesterday, yesterday, weixin_public_account_id
    end
  end

  # 创建一个微信接口数据interface_data.
  # ===参数说明
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * callback_count # 通过服务器配置地址获得消息后，被动回复用户消息的次数
  # * fail_count # 上述动作的失败次数
  # * total_time_cost # 总耗时，除以callback_count即为平均耗时
  # * max_time_cost # 最大耗时
  # * weixin_public_account_id # 公众账号ID
  # * interface_data_type # 数据类型，包括summary、summary_hour
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, interface_data_type: 'summary' ... }
  # ::EricWeixin::Report::InterfaceData.create_interface_data options
  def self.create_interface_data options
    self.transaction do
      options = get_arguments_options options, [:ref_date, :ref_hour, :callback_count, :fail_count, :total_time_cost, :max_time_cost,
                                                :weixin_public_account_id, :interface_data_type]
      interface_data = self.new options
      interface_data.save!
      interface_data.reload
      interface_data
    end
  end

  # 通过参数确定是否存在这样一个微信接口数据interface_data.
  # ===参数说明
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * callback_count # 通过服务器配置地址获得消息后，被动回复用户消息的次数
  # * fail_count # 上述动作的失败次数
  # * total_time_cost # 总耗时，除以callback_count即为平均耗时
  # * max_time_cost # 最大耗时
  # * weixin_public_account_id # 公众账号ID
  # * interface_data_type # 数据类型，包括summary、summary_hour
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, interface_data_type: 'summary' ... }
  # ::EricWeixin::Report::InterfaceData.exist options
  # ===返回
  # true 代表存在
  # false 代表不存在
  def self.exist options
    options = get_arguments_options options, [:ref_date, :ref_hour, :callback_count, :fail_count, :total_time_cost, :max_time_cost,
                                              :weixin_public_account_id, :interface_data_type]
    self.where( options ).count >= 1
  end

  # 获得公众平台官网数据统计模块中接口分析数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于30
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::InterfaceData.get_and_save_interface_summary '2015-5-1', '2015-5-30', 1
  def self.get_and_save_interface_summary begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      interface_summary = ::EricWeixin::AnalyzeData.get_interface_summary options
      pp "############################ interface_summary ####################################"
      pp interface_summary
      list_summary = interface_summary["list"]
      list_summary.each do |s|
        s = s.merge(interface_data_type: 'summary').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_interface_data s unless self.exist s
      end unless list_summary.blank?

    end
  end

  # 获得公众平台官网数据统计模块中接口分析分时数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::InterfaceData.get_and_save_interface_summary_hour '2015-5-1', '2015-5-1', 1
  def self.get_and_save_interface_summary_hour begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      interface_summary_hour = ::EricWeixin::AnalyzeData.get_interface_summary_hour options
      pp "############################ interface_summary_hour ####################################"
      pp interface_summary_hour
      list_summary_hour = interface_summary_hour["list"]
      list_summary_hour.each do |s|
        s = s.merge(interface_data_type: 'summary_hour').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_interface_data s unless self.exist s
      end unless list_summary_hour.blank?

    end
  end
end
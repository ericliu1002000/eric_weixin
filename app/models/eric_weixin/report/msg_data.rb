class EricWeixin::Report::MsgData < ActiveRecord::Base
  self.table_name = 'weixin_report_msg_data'

  MSG_DATA_TYPE = ['summary', 'msg_hour', 'msg_week', 'msg_month', 'msg_dist', 'msg_dist_week', 'msg_dist_month']
  MSG_TYPE = {
      1 => '代表文字',
      2 => '代表图片',
      3 => '代表语音',
      4 => '代表视频',
      6 => '代表第三方应用消息（链接消息）'
  }
  INTERVAL = {
      0 => '0',
      1 => '1-5',
      2 => '6-10',
      3 => '10次以上'
  }

  validates_presence_of :msg_data_type, message: "数据类型不可以为空。"
  validates_inclusion_of :msg_data_type, in: MSG_DATA_TYPE, message: "不正确的数据类型，只能为summary、msg_hour、msg_week、msg_month、msg_dist、msg_dist_week、msg_dist_month其中一个。"

  # 自动去微信服务器拉取当日之前的统计模块的消息数据.
  # ===参数说明
  # * weixin_public_account_id # 微信公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.auto_execute_get_and_save_data_from_weixin 1
  def self.auto_execute_get_and_save_data_from_weixin weixin_public_account_id
    self.transaction do
      # 若当前是周一，则取上周 整周 的数据
      if Time.now.to_date.cwday == 1
        s = (Time.now - 7.day).to_date.to_s
        get_and_save_upstream_msg_week s, s, weixin_public_account_id
        get_and_save_upstream_msg_dist_week s, s, weixin_public_account_id
      end
      # 获取昨天的数据
      d = (Time.now - 1.day).to_date.to_s
      get_and_save_upstream_msg d, d, weixin_public_account_id
      get_and_save_upstream_msg_hour d, d, weixin_public_account_id
      get_and_save_upstream_msg_dist d, d, weixin_public_account_id

      # 若当前是月初第一天，则取上个月的数据
      if Time.now.day == 1
        s = Time.now.last_month.beginning_of_month.to_date.to_s
        get_and_save_upstream_msg_month s, s, weixin_public_account_id
        get_and_save_upstream_msg_dist_month s, s, weixin_public_account_id
      end
    end
  end

  # 创建一个微信消息数据msg_data.
  # ===参数说明
  # * user_source # 数据来源
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * msg_type # 消息类型，代表含义如下：1代表文字 2代表图片 3代表语音 4代表视频 6代表第三方应用消息（链接消息）
  # * msg_user # 上行发送了（向公众号发送了）消息的用户数
  # * msg_count # 上行发送了消息的消息总数
  # * count_interval # 当日发送消息量分布的区间，0代表 “0”，1代表“1-5”，2代表“6-10”，3代表“10次以上”
  # * int_page_read_count # 图文页的阅读次数
  # * ori_page_read_user # 原文页（点击图文页“阅读原文”进入的页面）的阅读人数，无原文页时此处数据为0
  # * weixin_public_account_id # 公众号ID
  # * msg_data_type # 数据类型，包括summary、msg_hour、msg_week、msg_month、msg_dist、msg_dist_week、msg_dist_month
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, msg_data_type: 'summary' ... }
  # ::EricWeixin::Report::MsgData.create_msg_data options
  def self.create_msg_data options
    self.transaction do
      options = get_arguments_options options, [:user_source, :ref_date, :ref_hour, :msg_type, :msg_user, :msg_count, :count_interval,
                                                :int_page_read_count, :ori_page_read_user, :weixin_public_account_id, :msg_data_type ]
      msg_data = self.new options
      msg_data.save!
      msg_data.reload
      msg_data
    end
  end

  # 通过参数确定是否存在这样一个微信消息数据msg_data.
  # ===参数说明
  # * user_source # 数据来源
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * msg_type # 消息类型，代表含义如下：1代表文字 2代表图片 3代表语音 4代表视频 6代表第三方应用消息（链接消息）
  # * msg_user # 上行发送了（向公众号发送了）消息的用户数
  # * msg_count # 上行发送了消息的消息总数
  # * count_interval # 当日发送消息量分布的区间，0代表 “0”，1代表“1-5”，2代表“6-10”，3代表“10次以上”
  # * int_page_read_count # 图文页的阅读次数
  # * ori_page_read_user # 原文页（点击图文页“阅读原文”进入的页面）的阅读人数，无原文页时此处数据为0
  # * weixin_public_account_id # 公众号ID
  # * msg_data_type # 数据类型，包括summary、msg_hour、msg_week、msg_month、msg_dist、msg_dist_week、msg_dist_month
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, msg_data_type: 'summary' ... }
  # ::EricWeixin::Report::MsgData.exist options
  # ===返回
  # true 代表存在
  # false 代表不存在
  def self.exist options
    options = get_arguments_options options, [:user_source, :ref_date, :ref_hour, :msg_type, :msg_user, :msg_count, :count_interval,
                                              :int_page_read_count, :ori_page_read_user, :weixin_public_account_id, :msg_data_type ]
    self.where( options ).count >= 1
  end

  # 获得公众平台官网数据统计模块中消息发送概况数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于7
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg '2015-6-1', '2015-6-7', 1
  def self.get_and_save_upstream_msg begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }

      # 获取消息发送概况数据（getupstreammsg）
      # get_upstream_msg
      upstream_msg = ::EricWeixin::AnalyzeData.get_upstream_msg options
      pp "############################ upstream_msg ####################################"
      pp upstream_msg
      list_summary = upstream_msg["list"]
      list_summary.each do |s|
        s = s.merge(msg_data_type: 'summary').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_summary.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息分送分时数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_hour '2015-6-1', '2015-6-1', 1
  def self.get_and_save_upstream_msg_hour begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息分送分时数据（getupstreammsghour）
      # get_upstream_msg_hour
      upstream_msg_hour = ::EricWeixin::AnalyzeData.get_upstream_msg_hour options
      pp "############################ upstream_msg_hour ####################################"
      pp upstream_msg_hour
      list_msg_hour = upstream_msg_hour["list"]
      list_msg_hour.each do |s|
        s = s.merge(msg_data_type: 'msg_hour').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_hour.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息发送周数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于30
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_week '2015-5-1', '2015-5-30', 1
  def self.get_and_save_upstream_msg_week begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息发送周数据（getupstreammsgweek）
      # get_upstream_msg_week
      upstream_msg_week = ::EricWeixin::AnalyzeData.get_upstream_msg_week options
      pp "############################ upstream_msg_week ####################################"
      pp upstream_msg_week
      list_msg_week = upstream_msg_week["list"]
      list_msg_week.each do |s|
        s = s.merge(msg_data_type: 'msg_week').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_week.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息发送月数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于30
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_month '2015-5-1', '2015-5-30', 1
  def self.get_and_save_upstream_msg_month begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息发送月数据（getupstreammsgmonth）
      # get_upstream_msg_month
      upstream_msg_month = ::EricWeixin::AnalyzeData.get_upstream_msg_month options
      pp "############################ upstream_msg_month ####################################"
      pp upstream_msg_month
      list_msg_month = upstream_msg_month["list"]
      list_msg_month.each do |s|
        s = s.merge(msg_data_type: 'msg_month').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_month.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息发送分布数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于15
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_dist '2015-5-1', '2015-5-15', 1
  def self.get_and_save_upstream_msg_dist begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息发送分布数据（getupstreammsgdist）
      # get_upstream_msg_dist
      upstream_msg_dist = ::EricWeixin::AnalyzeData.get_upstream_msg_dist options
      pp "############################ upstream_msg_dist ####################################"
      pp upstream_msg_dist
      list_msg_dist = upstream_msg_dist["list"]
      list_msg_dist.each do |s|
        s = s.merge(msg_data_type: 'msg_dist').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_dist.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息发送分布周数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于30
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_dist_week '2015-5-1', '2015-5-30', 1
  def self.get_and_save_upstream_msg_dist_week begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息发送分布周数据（getupstreammsgdistweek）
      # get_upstream_msg_dist_week
      upstream_msg_dist_week = ::EricWeixin::AnalyzeData.get_upstream_msg_dist_week options
      pp "############################ upstream_msg_dist_week ####################################"
      pp upstream_msg_dist_week
      list_msg_dist_week = upstream_msg_dist_week["list"]
      list_msg_dist_week.each do |s|
        s = s.merge(msg_data_type: 'msg_dist_week').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_dist_week.blank?
    end
  end

  # 获得公众平台官网数据统计模块中消息发送分布月数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于30
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::MsgData.get_and_save_upstream_msg_dist_month '2015-5-1', '2015-5-30', 1
  def self.get_and_save_upstream_msg_dist_month begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # 获取消息发送分布月数据（getupstreammsgdistmonth）
      # get_upstream_msg_dist_month
      upstream_msg_dist_month = ::EricWeixin::AnalyzeData.get_upstream_msg_dist_month options
      pp "############################ upstream_msg_dist_month ####################################"
      pp upstream_msg_dist_month
      list_msg_dist_month = upstream_msg_dist_month["list"]
      list_msg_dist_month.each do |s|
        s = s.merge(msg_data_type: 'msg_dist_month').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_msg_data s unless self.exist s
      end unless list_msg_dist_month.blank?
    end
  end

end
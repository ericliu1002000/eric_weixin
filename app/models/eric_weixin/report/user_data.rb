class EricWeixin::Report::UserData < ActiveRecord::Base
  self.table_name = 'weixin_report_user_data'
  belongs_to :weixin_public_account

  USER_DATA_TYPE = ['summary', 'cumulate']
  USER_SOURCE ={
      0 => '其他',
      30 => '扫二维码',
      17 => '名片分享',
      35 => '搜号码',
      39 => '查询微信公众帐号',
      43 => '图文页右上角菜单'
  }

  validates_presence_of :user_data_type, message: "数据类型不可以为空。"
  validates_inclusion_of :user_data_type, in: USER_DATA_TYPE, message: "不正确的数据类型，只能为summary或cumulate"

  # 自动去微信服务器拉取当日之前的统计模块的用户数据.
  # ===参数说明
  # * weixin_public_account_id # 微信公众号ID
  # ===调用实例
  # ::EricWeixin::Report::UserData.auto_execute_get_and_save_data_from_weixin 1
  def self.auto_execute_get_and_save_data_from_weixin weixin_public_account_id
    yesterday = (Time.now - 1.day).to_date.to_s
    get_and_save_data_from_weixin yesterday, yesterday, weixin_public_account_id
  end

  # 创建一个微信用户数据user_data.
  # ===参数说明
  # * cumulate_user # 总用户量
  # * cancel_user # 取消关注的用户数量，new_user减去cancel_user即为净增用户数量
  # * new_user # 新增的用户数量
  # * ref_date # 数据的日期
  # * user_source # 用户的渠道，数值代表的含义如下：0代表其他 30代表扫二维码 17代表名片分享 35代表搜号码(即微信添加朋友页的搜索) 39代表查询微信公众帐号 43代表图文页右上角菜单
  # * weixin_public_account_id # 公众号id
  # * user_data_type # 数据类型, 包括 summary、cumulate, 分别代表用户增减数据、获取累计用户数据
  # ===调用实例
  # options = {cumulate_user: 100, cancel_user: 1, new_user: 9, ref_date: '2015-6-11', user_source: 0, weixin_public_account_id: 1, user_data_type: 'summary'}
  # ::EricWeixin::Report::UserData.create_user_data options
  def self.create_user_data options
    self.transaction do
      options = get_arguments_options options, [:cumulate_user, :cancel_user, :new_user, :ref_date, :user_source, :weixin_public_account_id, :user_data_type]
      user_data = self.new options
      user_data.save!
      user_data.reload
      user_data
    end
  end

  # 通过参数确定是否存在这样一个微信用户数据user_data.
  # ===参数说明
  # * cumulate_user # 总用户量
  # * cancel_user # 取消关注的用户数量，new_user减去cancel_user即为净增用户数量
  # * new_user # 新增的用户数量
  # * ref_date # 数据的日期
  # * user_source # 用户的渠道，数值代表的含义如下：0代表其他 30代表扫二维码 17代表名片分享 35代表搜号码(即微信添加朋友页的搜索) 39代表查询微信公众帐号 43代表图文页右上角菜单
  # * weixin_public_account_id # 公众号id
  # * user_data_type # 数据类型, 包括 summary、cumulate, 分别代表用户增减数据、获取累计用户数据
  # ===调用实例
  # options = {cumulate_user: 100, cancel_user: 1, new_user: 9, ref_date: '2015-6-11', user_source: 0, weixin_public_account_id: 1, user_data_type: 'summary'}
  # ::EricWeixin::Report::UserData.exist options
  # ===返回
  # true 代表存在
  # false 代表不存在
  def self.exist options
    options = get_arguments_options options, [:cancel_user, :new_user, :ref_date, :user_source, :weixin_public_account_id, :user_data_type]
    self.where( options ).count >= 1
  end

  # 获得公众平台官网数据统计模块中用户分析数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于7
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::UserData.get_and_save_data_from_weixin '2015-6-1', '2015-6-6', 1
  def self.get_and_save_data_from_weixin begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      user_summary = ::EricWeixin::AnalyzeData.get_user_summary options
      list_summary = user_summary["list"]
      list_summary.each do |s|
        s = s.merge(user_data_type: 'summary').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_user_data s unless self.exist s
      end unless list_summary.blank?
      user_cumulate = ::EricWeixin::AnalyzeData.get_user_cumulate options
      list_cumulate = user_cumulate["list"]
      list_cumulate.each do |s|
        s = s.merge(user_data_type: 'cumulate').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_user_data s unless self.exist s
      end unless list_cumulate.blank?
    end
  end
end
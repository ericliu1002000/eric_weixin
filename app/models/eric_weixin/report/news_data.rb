class EricWeixin::Report::NewsData < ActiveRecord::Base
  self.table_name = 'weixin_report_news_data'

  NEWS_DATA_TYPE = ['summary', 'total', 'read', 'read_hour', 'share', 'share_hour']
  SHARE_SCENE = {
      1 => '好友转发',
      2 => '朋友圈',
      3 => '腾讯微博',
      255 => '其他'
  }

  validates_presence_of :news_data_type, message: "数据类型不可以为空。"
  validates_inclusion_of :news_data_type, in: NEWS_DATA_TYPE, message: "不正确的数据类型，只能为summary、total、read、read_hour、share、share_hour其中一个。"

  # 自动去微信服务器拉取当日前一天的统计模块的图文数据.
  # ===参数说明
  # * weixin_public_account_id # 微信公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.auto_execute_get_and_save_data_from_weixin 1
  def self.auto_execute_get_and_save_data_from_weixin weixin_public_account_id
    self.transaction do
      yesterday = (Time.now - 1.day).to_date.to_s
      # 取当天的前一天数据
      get_and_save_data_from_weixin yesterday, yesterday, weixin_public_account_id
      get_and_save_article_total yesterday, yesterday, weixin_public_account_id
      get_and_save_user_read_hour yesterday, yesterday, weixin_public_account_id
      get_and_save_user_share_hour yesterday, yesterday, weixin_public_account_id
      get_and_save_user_share yesterday, yesterday, weixin_public_account_id
      get_and_save_user_read yesterday, yesterday, weixin_public_account_id
    end
  end

  # 创建一个微信图文数据news_data.
  # ===参数说明
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * stat_date # 统计的日期，在getarticletotal接口中，ref_date指的是文章群发出日期， 而stat_date是数据统计日期
  # * msgid # 这里的msgid实际上是由msgid（图文消息id）和index（消息次序索引）组成， 例如12003_3， 其中12003是msgid，即一次群发的id消息的； 3为index，假设该次群发的图文消息共5个文章（因为可能为多图文）， 3表示5个中的第3个
  # * title # 图文消息的标题
  # * int_page_read_user # 图文页（点击群发图文卡片进入的页面）的阅读人数
  # * int_page_read_count # 图文页的阅读次数
  # * ori_page_read_user # 原文页（点击图文页“阅读原文”进入的页面）的阅读人数，无原文页时此处数据为0
  # * ori_page_read_count # 原文页的阅读次数
  # * share_scene # 分享的场景 1代表好友转发 2代表朋友圈 3代表腾讯微博 255代表其他
  # * share_user # 分享的人数
  # * share_count # 分享的次数
  # * add_to_fav_user # 收藏的人数
  # * add_to_fav_count # 收藏的次数
  # * target_user # 送达人数，一般约等于总粉丝数（需排除黑名单或其他异常情况下无法收到消息的粉丝）
  # * weixin_public_account_id # 公众号ID
  # * news_data_type # 数据类型，包括summary、total、read、read_hour、share、share_hour
  # * user_source # 数据来源
  # * total_online_time # 总在线时间
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, news_data_type: 'summary' ... }
  # ::EricWeixin::Report::NewsData.create_news_data options
  def self.create_news_data options
    self.transaction do
      options = get_arguments_options options, [:ref_date, :ref_hour, :stat_date, :msgid, :title,
                                                :int_page_read_user, :int_page_read_count, :ori_page_read_user, :ori_page_read_count,
                                                :share_scene, :share_user, :share_count, :add_to_fav_user, :add_to_fav_count,
                                                :target_user, :weixin_public_account_id, :news_data_type, :user_source, :total_online_time]
      news_data = self.new options
      news_data.save!
      news_data.reload
      news_data
    end
  end

  # 通过参数确定是否存在这样一个微信图文数据news_data.
  # ===参数说明
  # * ref_date # 数据的日期
  # * ref_hour # 数据的小时，包括从000到2300，分别代表的是[000,100)到[2300,2400)，即每日的第1小时和最后1小时
  # * stat_date # 统计的日期，在getarticletotal接口中，ref_date指的是文章群发出日期， 而stat_date是数据统计日期
  # * msgid # 这里的msgid实际上是由msgid（图文消息id）和index（消息次序索引）组成， 例如12003_3， 其中12003是msgid，即一次群发的id消息的； 3为index，假设该次群发的图文消息共5个文章（因为可能为多图文）， 3表示5个中的第3个
  # * title # 图文消息的标题
  # * int_page_read_user # 图文页（点击群发图文卡片进入的页面）的阅读人数
  # * int_page_read_count # 图文页的阅读次数
  # * ori_page_read_user # 原文页（点击图文页“阅读原文”进入的页面）的阅读人数，无原文页时此处数据为0
  # * ori_page_read_count # 原文页的阅读次数
  # * share_scene # 分享的场景 1代表好友转发 2代表朋友圈 3代表腾讯微博 255代表其他
  # * share_user # 分享的人数
  # * share_count # 分享的次数
  # * add_to_fav_user # 收藏的人数
  # * add_to_fav_count # 收藏的次数
  # * target_user # 送达人数，一般约等于总粉丝数（需排除黑名单或其他异常情况下无法收到消息的粉丝）
  # * weixin_public_account_id # 公众号ID
  # * news_data_type # 数据类型，包括summary、total、read、read_hour、share、share_hour
  # * user_source # 数据来源
  # * total_online_time # 总在线时间
  # ===调用实例
  # options = {ref_date: '2015-6-6', ref_hour: 0, weixin_public_account_id: 1, news_data_type: 'summary' ... }
  # ::EricWeixin::Report::NewsData.exist options
  # ===返回
  # true 代表存在
  # false 代表不存在
  def self.exist options
    options = get_arguments_options options, [:ref_date, :ref_hour, :stat_date, :msgid, :title,
                                              :int_page_read_user, :int_page_read_count, :ori_page_read_user, :ori_page_read_count,
                                              :share_scene, :share_user, :share_count, :add_to_fav_user, :add_to_fav_count,
                                              :target_user, :weixin_public_account_id, :news_data_type, :user_source, :total_online_time]
    self.where( options ).count >= 1
  end

  # 获得公众平台官网数据统计模块中图文群发每日数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_data_from_weixin '2015-6-1', '2015-6-1', 1
  def self.get_and_save_data_from_weixin begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_article_summary
      article_summary = ::EricWeixin::AnalyzeData.get_article_summary options
      pp "############################ article_summary ####################################"
      pp article_summary
      list_summary = article_summary["list"]
      list_summary.each do |s|
        s = s.merge(news_data_type: 'summary').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_news_data s unless self.exist s
      end unless list_summary.blank?
    end
  end

  # 获得公众平台官网数据统计模块中图文群发总数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_article_total '2015-6-1', '2015-6-1', 1
  def self.get_and_save_article_total begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_article_total
      article_total = ::EricWeixin::AnalyzeData.get_article_total options
      pp "############################ article_total ####################################"
      pp article_total
      list_total = article_total["list"]
      list_total.each do |s|
        s = s.merge(news_data_type: 'total').merge(weixin_public_account_id: weixin_public_account_id)
        details = s["details"]
        details.each do |d|
          self.create_news_data s.merge(d) unless self.exist s.merge(d)
        end unless details.blank?
      end unless list_total.blank?
    end
  end

  # 获得公众平台官网数据统计模块中图文统计数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于3
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_user_read '2015-6-1', '2015-6-3', 1
  def self.get_and_save_user_read begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_user_read
      user_read = ::EricWeixin::AnalyzeData.get_user_read options
      pp "############################ user_read ####################################"
      pp user_read
      list_read = user_read["list"]
      list_read.each do |s|
        s = s.merge(news_data_type: 'read').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_news_data s unless self.exist s
      end unless list_read.blank?
    end
  end

  # 获得公众平台官网数据统计模块中图文统计分时数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_user_read_hour '2015-6-1', '2015-6-1', 1
  def self.get_and_save_user_read_hour begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_user_read_hour
      user_read_hour = ::EricWeixin::AnalyzeData.get_user_read_hour options
      pp "############################ user_read_hour ####################################"
      pp user_read_hour
      list_read_hour = user_read_hour["list"]
      list_read_hour.each do |s|
        s = s.merge(news_data_type: 'read_hour').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_news_data s unless self.exist s
      end unless list_read_hour.blank?
    end
  end

  # 获得公众平台官网数据统计模块中图文分享转发数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于7
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_user_share '2015-6-1', '2015-6-7', 1
  def self.get_and_save_user_share begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_user_share
      user_share = ::EricWeixin::AnalyzeData.get_user_share options
      pp "############################ user_share ####################################"
      pp user_share
      list_share = user_share["list"]
      list_share.each do |s|
        s = s.merge(news_data_type: 'share').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_news_data s unless self.exist s
      end unless list_share.blank?
    end
  end

  # 获得公众平台官网数据统计模块中图文分享转发分时数据&保存到数据库.
  # ===参数说明
  # * begin_date # 获取数据的起始日期，begin_date和end_date的差值需小于1
  # * end_date # 获取数据的结束日期，end_date允许设置的最大值为昨日
  # * weixin_public_account_id # 公众号ID
  # ===调用实例
  # ::EricWeixin::Report::NewsData.get_and_save_user_share_hour '2015-6-1', '2015-6-1', 1
  def self.get_and_save_user_share_hour begin_date, end_date, weixin_public_account_id
    self.transaction do
      options = {
          :begin_date => begin_date,
          :end_date => end_date,
          :weixin_public_account_id => weixin_public_account_id
      }
      # get_user_share_hour
      user_share_hour = ::EricWeixin::AnalyzeData.get_user_share_hour options
      pp "############################ user_share_hour ####################################"
      pp user_share_hour
      list_share_hour = user_share_hour["list"]
      list_share_hour.each do |s|
        s = s.merge(news_data_type: 'share_hour').merge(weixin_public_account_id: weixin_public_account_id)
        self.create_news_data s unless self.exist s
      end unless list_share_hour.blank?

    end
  end
end
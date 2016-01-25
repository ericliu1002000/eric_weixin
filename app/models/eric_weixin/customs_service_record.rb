class EricWeixin::CustomsServiceRecord < ActiveRecord::Base
  self.table_name = 'weixin_customs_service_records'
  belongs_to :public_account, class_name: "PublicAccount", foreign_key: "weixin_public_account_id"
  OPERCODE = {
    1000 => "创建未接入会话",
    1001 =>	"接入会话",
    1002 =>	"主动发起会话",
    1004 =>	"关闭会话",
    1005 =>	"抢接会话",
    2001 =>	"公众号收到消息",
    2002 =>	"客服发送消息",
    2003 =>	"客服收到消息"
  }

  validates_uniqueness_of :time, scope: [:openid, :weixin_public_account_id, :text], message: '客服聊天记录不能重复。'

  def self.create_one options
    self.transaction do
      options = get_arguments_options options, [:weixin_public_account_id, :openid, :opercode, :text, :time, :worker]
      re = self.new options
      re.save!
      re.reload
      re
    end

  end

  def self.exist_one options
    options = get_arguments_options options, [:weixin_public_account_id, :openid, :opercode, :text, :time, :worker]
    self.where( options ).count >= 1
  end


  # 批量获取用户与客服的聊天记录保存到数据库.
  # ===参数说明
  # * chat_date  #聊天日期
  # ===调用说明
  #  ::EricWeixin::CustomsServiceRecord.batch_get_customs_records '2015-6-9'.to_time
  def self.batch_get_customs_records chat_date
    self.transaction do
      chat_date = chat_date.to_time
      start_time_unix = chat_date.change(hour: 0, min: 0, sec: 0).to_i
      end_time_unix = chat_date.change(hour: 23, min:59, sec: 59).to_i
      message_logs = ::EricWeixin::MessageLog.where("create_time between ? and ? ", start_time_unix, end_time_unix)
      message_logs = message_logs.where(event_name: 'kf_create_session', process_status: 1).group(:openid, :weixin_public_account_id)
      message_logs.each do |message_log|
        options = {
            :weixin_public_account_id=>message_log.weixin_public_account_id,
            :openid=>message_log.openid,
            :starttime=>start_time_unix,
            :endtime=>end_time_unix,
            :pageindex=>1
        }
        i = 1
        has_record = true
        while has_record
          options[:pageindex] = i
          result_code, has_record = ::EricWeixin::MultCustomer.get_customer_service_messages options
          BusinessException.raise '获取聊天记录失败' unless result_code == 0
          i += 1
          BusinessException.raise '此人聊天记录竟然上了5000条！' if i >= 100
        end
        all_message_logs = ::EricWeixin::MessageLog.where("create_time between ? and ? ", start_time_unix, end_time_unix)
        all_message_logs = all_message_logs.where(event_name: 'kf_create_session', process_status: 1, openid: message_log.openid, weixin_public_account_id: message_log.weixin_public_account_id)
        all_message_logs.each{ |ml| ml.update_attribute :process_status, 0 }
      end
    end
  end

  def nick_name
    ::EricWeixin::WeixinUser.find_by_openid(self.openid).nickname rescue ''
  end

  def wixin_user
    ::EricWeixin::WeixinUser.find_by_openid(self.openid)
  end

  def self.common_query options
    records = self.all

    records = records.where(weixin_public_account_id: options[:public_account_id]) unless options[:public_account_id].blank?

    records = records.where(opercode: options[:opercode]) unless options[:opercode].blank?

    unless options[:chat_date].blank?
      start_time = options[:chat_date].to_time.change(hour:0, min:0, sec:0).to_i
      end_time = options[:chat_date].to_time.change(hour:23, min:59, sec:59).to_i
      records = records.where("time between ? and ?", start_time, end_time)
    end

    #todo 这里的查询方式有可能有问题，建议取消此类查询。
    records = records.where("text like ?", "%#{options[:chat_content]}%") unless options[:chat_content].blank?

    records = records.where("worker like ?", "%#{options[:worker]}%") unless options[:worker].blank?

    unless options[:nick_name].blank?
      records = records.joins('LEFT JOIN weixin_users ON weixin_users.openid = weixin_customs_service_records.openid')
      records = records.where("weixin_users.nickname like ?", "%#{options[:nick_name]}%")
    end

    records
  end
end

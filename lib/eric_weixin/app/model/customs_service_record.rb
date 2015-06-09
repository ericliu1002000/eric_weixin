class EricWeixin::CustomsServiceRecord < ActiveRecord::Base
  self.table_name = 'weixin_customs_service_records'

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

  def self.batch_get_customs_records chat_date
    self.transaction do
      chat_date = chat_date.to_time
      start_time_unix = chat_date.change(hour: 0, min: 0, sec: 0).to_i
      end_time_unix = chat_date.change(hour: 23, min:59, sec: 59).to_i
      message_logs = ::EricWeixin::MessageLog.where("create_time between ? and ? ", start_time_unix, end_time_unix)
      message_logs = message_logs.where(event_name: 'kf_create_session', process_status: 1).group(:openid)
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
        message_log.update_attribute :process_status, 0
      end
    end
  end

end

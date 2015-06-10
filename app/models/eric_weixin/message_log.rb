class EricWeixin::MessageLog < ActiveRecord::Base

  STATUS = {0 => '正常', 1 => '待处理'}
  self.table_name = "weixin_message_logs"
  belongs_to :public_account, class_name: "::EricWeixin::PublicAccount", foreign_key: "weixin_public_account_id"
  validates_presence_of :public_account,
                        message: '公众账号必须存在'

  class << self

    def create_public_account_receive_message_log options
      options = options.select{|k,v| [:openid,:event_key, :weixin_public_account_id, :message_type, :message_id, :data, :passive_reply_message, :process_status, :event_name, :create_time, :parent_id].include? k }
      options[:account_receive_flg] = 0
      self.create_message_log options
    end

    def create_public_account_send_message_log options
      options = options.select{|k,v| [:openid, :event_key,:weixin_public_account_id, :message_type, :message_id, :data, :passive_reply_message, :process_status, :event_name, :create_time, :parent_id].include? k }
      options[:account_receive_flg] = 1
      self.create_message_log options
    end

    def create_message_log options
      ::EricWeixin::MessageLog.transaction do
        log = ::EricWeixin::MessageLog.new options.select{|k,v| [:openid,:event_key, :weixin_public_account_id, :message_type, :message_id, :data, :account_receive_flg, :passive_reply_message, :process_status, :event_name, :create_time, :parent_id].include? k }
        log.save!
        log
      end
    end


  end
end



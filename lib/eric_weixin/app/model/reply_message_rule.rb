class EricWeixin::ReplyMessageRule < ActiveRecord::Base
  self.table_name = 'weixin_reply_message_rules'
  scope :valid, -> { where(:is_valid => true) }
  belongs_to :weixin_public_account, :class_name => '::EricWeixin::PublicAccount', foreign_key: "weixin_public_account_id"
  delegate :name, to: :weixin_public_account, prefix: true, allow_nil: true

  KEY_WORD_TYPE_LABEL = {"keyword" => '字符', 'regularexpr' => '正则表达式'}
  REPLY_TYPE_LABEL = {"text" => '静态字符串', 'wx_function' => '动态运行', 'news' => '多图文'}

  class << self

    def create_reply_message_rule options
      options = get_arguments_options options, [:weixin_public_account_id, :key_word, :reply_message, :key_word_type, :order, :reply_type], is_valid: true
      ::EricWeixin::ReplyMessageRule.transaction do
        reply_message_rule = ::EricWeixin::ReplyMessageRule.new options
        public_account = ::EricWeixin::PublicAccount.find(options[:weixin_public_account_id])
        reply_message_rule.weixin_app_id = public_account.weixin_app_id
        reply_message_rule.weixin_secret_key = public_account.weixin_secret_key
        reply_message_rule.save!
        reply_message_rule
      end
    end

    def update_reply_message_rule(rule_id, options)
      options = get_arguments_options options, [:weixin_public_account_id, :key_word, :reply_message, :key_word_type, :order, :reply_type, :is_valid]
      EricWeixin::ReplyMessageRule.transaction do
        rule = EricWeixin::ReplyMessageRule.find(rule_id)
        rule.update_attributes(options)
        public_account = ::EricWeixin::PublicAccount.find(options[:weixin_public_account_id])
        rule.weixin_app_id = public_account.weixin_app_id
        rule.weixin_secret_key = public_account.weixin_secret_key
        rule.save!
        rule
      end
    end

    def process_rule(receive_message, secret_key)
      business_type = "#{receive_message[:MsgType]}~#{receive_message[:Event]}"


      reply_message = case business_type
                        #订阅
                        when /event~subscribe/
                          result = ::Weixin::Process.subscribe receive_message
                          if result == true
                            ::EricWeixin::WeixinUser.create_weixin_user secret_key, receive_message[:FromUserName]
                            match_key_words 'subscribe', secret_key, receive_message
                          else
                            result
                          end

                        #取消订阅
                        when /event~unsubscribe/
                          result = ::Weixin::Process.unsubscribe receive_message
                          if result == true
                            ::EricWeixin::WeixinUser.create_weixin_user secret_key, receive_message[:FromUserName]
                            match_key_words 'unsubscribe', secret_key, receive_message
                          else
                            result
                          end

                        #点击消息
                        when /event~CLICK/
                          result = ::Weixin::Process.click_event receive_message[:EventKey], receive_message
                          if result == true
                            match_key_words receive_message[:EventKey], secret_key, receive_message
                          else
                            result
                          end

                        #模板发送完毕通知消息
                        when /event~TEMPLATESENDJOBFINISH/
                          EricWeixin::update_template_message_status receive_message[:ToUserName], receive_message[:MsgID], receive_message[:Status]
                          ::Weixin::Process.template_send_job_finish receive_message
                          ''

                        #文本消息
                        when /text~/
                          result = ::Weixin::Process.text_event receive_message[:Content], receive_message
                          if result == true
                            match_key_words receive_message[:Content], secret_key, receive_message
                          else
                            result
                          end

                        #暂时识别不了的消息
                        else
                          result = ::Weixin::Process.another_event receive_message
                          if result == true
                            match_key_words 'unknow~words', secret_key, receive_message
                          else
                            result
                          end
                      end
      "message_to_wechat:".to_logger
      reply_message.to_logger
      reply_message
    end

    def match_key_words wx_key_word, secret_key, receive_message
      matched_rule = EricWeixin::ReplyMessageRule.order(order: :desc).
          where(:key_word => wx_key_word, :weixin_secret_key => secret_key).first
      if matched_rule.nil?
        return EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: receive_message[:FromUserName],
                                                                        FromUserName: receive_message[:ToUserName]
      end
      reply_msg = case matched_rule.reply_type
                    when "text"
                      EricWeixin::ReplyMessage.get_reply_user_message_text ToUserName: receive_message[:FromUserName],
                                                                           FromUserName: receive_message[:ToUserName],
                                                                           Content: matched_rule.reply_message
                    when "news"
                      weixin_news = ::EricWeixin::News.find_by_match_key matched_rule.reply_message
                      EricWeixin::ReplyMessage::get_reply_user_message_image_text ToUserName: receive_message[:FromUserName],
                                                                                  FromUserName: receive_message[:ToUserName],
                                                                                  news: weixin_news.weixin_articles
                    when "wx_function"
                      Weixin::WeixinAutoReplyFunctions.send(matched_rule.reply_message, {:key_word => wx_key_word, :receive_message => receive_message})
                  end
      reply_msg
    end
  end
end
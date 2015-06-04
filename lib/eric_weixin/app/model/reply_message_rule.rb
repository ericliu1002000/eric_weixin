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
        reply_message_rule.save!
        reply_message_rule
      end
    end

    def update_reply_message_rule(rule_id, options)
      options = get_arguments_options options, [:weixin_public_account_id, :key_word, :reply_message, :key_word_type, :order, :reply_type, :is_valid]
      EricWeixin::ReplyMessageRule.transaction do
        rule = EricWeixin::ReplyMessageRule.find(rule_id)
        rule.update_attributes(options)
        rule.save!
        rule
      end
    end

    def process_rule(receive_message, public_account)
      business_type = "#{receive_message[:MsgType]}~#{receive_message[:Event]}"

      #兼容腾讯的一个坑....有的是MsgId， 有的是MsgID
      receive_message[:MsgId] = receive_message[:MsgID] if (!receive_message[:MsgID].blank? and receive_message[:MsgId].blank?)

      pa = ::EricWeixin::PublicAccount.find_by_weixin_number receive_message[:ToUserName]
      log = ::EricWeixin::MessageLog.create_public_account_receive_message_log openid: receive_message[:FromUserName],
                                                                               weixin_public_account_id: pa.id,
                                                                               message_type: receive_message[:MsgType],
                                                                               message_id: receive_message[:MsgId] || receive_message[:MsgID],
                                                                               data: receive_message.to_json,
                                                                               process_status: 0, #在这里假设都处理完毕，由业务引起的更新请在工程的Process中进行修改。
                                                                               event_name: receive_message[:Event],
                                                                               event_key: receive_message[:EventKey], #事件值
                                                                               create_time: receive_message[:CreateTime]
      business_type.to_debug

      reply_message = case business_type
                        #订阅
                        when /event~subscribe/
                          result = ::Weixin::Process.subscribe receive_message
                          if result == true
                            ::EricWeixin::WeixinUser.create_weixin_user public_account.id, receive_message[:FromUserName],receive_message[:EventKey]
                            match_key_words 'subscribe', public_account.id, receive_message
                          else
                            result
                          end

                        #取消订阅
                        when /event~unsubscribe/
                          result = ::Weixin::Process.unsubscribe receive_message
                          if result == true
                            ::EricWeixin::WeixinUser.create_weixin_user public_account.id, receive_message[:FromUserName]
                            ''
                          else
                            result
                          end

                        #点击消息
                        when /event~CLICK/
                          result = ::Weixin::Process.click_event receive_message[:EventKey], receive_message
                          if result == true
                            match_key_words receive_message[:EventKey], public_account.id, receive_message
                          else
                            result
                          end

                        #点击消息
                        when /event~SCAN/
                          result = ::Weixin::Process.scan_event receive_message[:EventKey], receive_message
                          if result == true
                            match_key_words "scan_#{receive_message[:EventKey]}", public_account.id, receive_message, false
                          else
                            result
                          end

                        #查看网页事件
                        when /event~VIEW/
                          result = ::Weixin::Process.view_event receive_message[:EventKey], receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        when /event~kf_close_session/
                          result = ::Weixin::Process.kv_close_session receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        when /event~kf_create_session/
                          #待取回客服聊天列表，所以标记为待处理
                          log.process_status = 1
                          log.save!
                          result = ::Weixin::Process.kv_create_session receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        #用户自动上报地理位置信息
                        when /event~LOCATION/
                          result = ::Weixin::Process.auto_location_event receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        #用户共享地理位置信息
                        when /location~/
                          result = ::Weixin::Process.location_event receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        #模板发送完毕通知消息
                        when /event~TEMPLATESENDJOBFINISH/
                          ::EricWeixin::TemplateMessageLog.update_template_message_status receive_message[:FromUserName], receive_message[:MsgID], receive_message[:Status]
                          ::Weixin::Process.template_send_job_finish receive_message
                          ''

                        #文本消息
                        when /text~/
                          result = ::Weixin::Process.text_event receive_message[:Content], receive_message
                          if result == true
                            match_key_words receive_message[:Content], public_account.id, receive_message
                          else
                            result
                          end

                        when /link~/
                          result = ::Weixin::Process.link_event receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                        #暂时识别不了的消息
                        else
                          "暂时未处理的场景".to_logger
                          receive_message.to_logger
                          result = ::Weixin::Process.another_event receive_message
                          if result == true
                            match_key_words 'unknow~words', public_account.id, receive_message
                          else
                            result
                          end
                      end
      "message_to_wechat:".to_logger
      reply_message.to_logger

      unless receive_message.to_s.blank?
        log.passive_reply_message = reply_message.to_s
        log.save!
      end

      reply_message
    end

    def match_key_words wx_key_word, public_account_id, receive_message,need_to_mult_service=true
      matched_rule = EricWeixin::ReplyMessageRule.order(order: :desc).
          where(:key_word => wx_key_word, :weixin_public_account_id => public_account_id, :key_word_type=>(receive_message[:MsgType]||"keyword")).first
      if matched_rule.nil?
        if need_to_mult_service
          return EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: receive_message[:FromUserName],
                                                                          FromUserName: receive_message[:ToUserName]
        else
          return '' #当匹配不上，也不需要去多客服的时候，就直接返回。
        end

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
                      ::Weixin::WeixinAutoReplyFunctions.send(matched_rule.reply_message, ({:key_word => wx_key_word, :receive_message => receive_message}))
                  end
      reply_msg
    end
  end
end
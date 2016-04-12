class EricWeixin::ReplyMessageRule < ActiveRecord::Base
  self.table_name = 'weixin_reply_message_rules'
  scope :valid, -> { where(:is_valid => true) }
  belongs_to :weixin_public_account, :class_name => '::EricWeixin::PublicAccount', foreign_key: "weixin_public_account_id"
  delegate :name, to: :weixin_public_account, prefix: true, allow_nil: true
  KEY_WORD_TYPE_LABEL = {"text" => '字符', 'regularexpr' => '正则表达式', 'event' => '事件'}

  REPLY_TYPE_LABEL = {"text" => '静态字符串', 'wx_function' => '动态运行', 'news' => '多图文'}

  validates_presence_of :key_word, message: "关键词不能为空。"
  validates_presence_of :reply_message, message: "回复信息不能为空。"
  validates_presence_of :weixin_public_account, message: "对应的微信公众账号不能为空。"
  validates_inclusion_of :reply_type, in: REPLY_TYPE_LABEL.collect { |r| r.first }, message: "不正确的回复类型。"
  validates_inclusion_of :key_word_type, in: KEY_WORD_TYPE_LABEL.collect { |r| r.first }, message: "不正确的关键词类型。"


  class << self

    #创建匹配规则
    def create_reply_message_rule options
      options = get_arguments_options options, [:weixin_public_account_id, :key_word, :reply_message, :key_word_type, :order, :reply_type], is_valid: true
      ::EricWeixin::ReplyMessageRule.transaction do
        reply_message_rule = ::EricWeixin::ReplyMessageRule.new options
        reply_message_rule.save!
        reply_message_rule
      end
    end

    # 更新匹配规则
    def update_reply_message_rule(rule_id, options)
      options = get_arguments_options options, [:weixin_public_account_id, :key_word, :reply_message, :key_word_type, :order, :reply_type, :is_valid]
      ::EricWeixin::ReplyMessageRule.transaction do
        rule = ::EricWeixin::ReplyMessageRule.find(rule_id)
        rule.update_attributes(options)
        rule.save!
        rule
      end
    end


    #处理来自微信端客户所有的处理。
    def process_rule(receive_message, public_account)
      receive_message_log = receive_message.clone
      receive_message_log[:Content] = receive_message_log[:Content] if not receive_message_log[:Content].blank?
      business_type = "#{receive_message[:MsgType]}~#{receive_message[:Event]}"

      #兼容腾讯的一个坑....有的是MsgId， 有的是MsgID
      receive_message[:MsgId] = receive_message[:MsgID] if (!receive_message[:MsgID].blank? and receive_message[:MsgId].blank?)


      log = ::EricWeixin::MessageLog.create_public_account_receive_message_log openid: receive_message[:FromUserName],
                                                                               weixin_public_account_id: public_account.id,
                                                                               message_type: receive_message[:MsgType],
                                                                               message_id: receive_message[:MsgId] || receive_message[:MsgID],
                                                                               data: receive_message_log.to_json,
                                                                               process_status: 0, #在这里假设都处理完毕，由业务引起的更新请在工程的Process中进行修改。
                                                                               event_name: receive_message[:Event],
                                                                               event_key: receive_message[:EventKey], #事件值
                                                                               create_time: receive_message[:CreateTime]
      business_type.to_debug

      reply_message = case business_type
                        #订阅
                        when /event~subscribe/
                          user, is_new = ::EricWeixin::WeixinUser.create_weixin_user public_account.id, receive_message[:FromUserName], receive_message[:EventKey]
                          result = ::Weixin::Process.subscribe receive_message, is_new
                          if result == true
                            match_key_words 'subscribe', public_account.id, receive_message, false
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

                        #点击消息,点击菜单时响应。
                        when /event~CLICK/
                          result = ::Weixin::Process.click_event receive_message[:EventKey], receive_message
                          if result == true
                            match_key_words receive_message[:EventKey], public_account.id, receive_message, false
                          else
                            result
                          end

                        #扫描带参数二维码


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
                            # if receive_message[:Content] == "我要找客服"
                            #   ::EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: receive_message[:FromUserName],
                            #                                                              FromUserName: receive_message[:ToUserName]
                            # else
                            match_key_words receive_message[:Content], public_account.id, receive_message
                            # end
                          else
                            result
                          end

                        when /image~/
                          result = ::Weixin::Process.image_event receive_message[:Content], receive_message
                          if result == true
                            ''
                          end

                        when /link~/
                          result = ::Weixin::Process.link_event receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                          # 微信小店订单通知。
                        when /event~merchant_order/
                          EricWeixin::Xiaodian::Order.create_order receive_message
                          result = ::Weixin::Process.get_merchant_order receive_message
                          if result == true
                            ''
                          else
                            result
                          end

                          # 群发发送图文推送后，微信服务器返回的结果
                        when /event~MASSSENDJOBFINISH/
                          ::EricWeixin::MediaNews.update_media_news_after_sending receive_message
                          ::Weixin::Process.message_send_job_finish receive_message
                          ''

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


    # 用户发送的关键字、 事件关键字匹配处理。
    # 关键字处理分三类： 事件关键字、 正则表达式关键字、 文本严格匹配关键字
    # 关键字匹配好以后，返回类型有三种： 文本、 图文、以及动态运行。
    #
    #  need_to_mult_service  如果匹配不到，是否提示转客服。
    def match_key_words wx_key_word, public_account_id, receive_message, need_to_mult_service=true

      message_type = receive_message[:MsgType]||"text"
      reply_message_rule = nil
      case message_type
        when 'event'
          # event类型关键字   event类型关键字不需要匹配正则表达式。
          reply_message_rule = ::EricWeixin::ReplyMessageRule.order(order: :desc).valid.
              where(weixin_public_account_id: public_account_id, key_word_type: 'event', key_word: wx_key_word).first
        else
          #  对于非event类型的关键字， 按照order 的优先级，逐条比对。 如果order相同，文本类型优先。 匹配成功就停止。
          rules = ::EricWeixin::ReplyMessageRule.order(order: :desc).valid.
              where(weixin_public_account_id: public_account_id, key_word_type: ['regularexpr', 'text'])
          rules.each do |rule|
            if rule.key_word_type == 'text'
              if wx_key_word == rule.key_word
                reply_message_rule = rule
                break
              end
            end
            if rule.key_word_type == 'regularexpr'
              # 一个正则式类型的关键字, 可以是以空格隔开的几个词, 如果其中有匹配的,就使用这条规则
              wxwords = wx_key_word.split(' ')
              regexp = Regexp.new rule.key_word
              wxwords.each do |word|
                r = regexp.match word
                unless r.blank?
                  reply_message_rule = rule
                  break
                end
              end # wxwords.each
            end # if rule.key_word_type
          end # rules.each
      end


      # if need_to_mult_service
      #   return ::EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: receive_message[:FromUserName],
      #                                                                   FromUserName: receive_message[:ToUserName]
      # else
      #   return '' #当匹配不上，也不需要去多客服的时候，就直接返回。
      # end


      reply_msg = if reply_message_rule.blank?
                    if need_to_mult_service
                      # 返回给用户，如何唤醒客服。
                      message = ::EricWeixin::ReplyMessageRule.get_contact_customer_notice public_account_id
                      if message.blank?
                        ''
                      else
                        ::EricWeixin::ReplyMessage.get_reply_user_message_text ToUserName: receive_message[:FromUserName],
                                                                               FromUserName: receive_message[:ToUserName],
                                                                               Content: message
                      end
                    else
                      ''
                    end

                  else

                    if reply_message_rule.reply_message == 'CONTACT_CUSTOMER_NOTICE'
                      ::EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: receive_message[:FromUserName],
                                                                                 FromUserName: receive_message[:ToUserName]
                    else
                      case reply_message_rule.reply_type
                        when "text"
                          ::EricWeixin::ReplyMessage.get_reply_user_message_text ToUserName: receive_message[:FromUserName],
                                                                                 FromUserName: receive_message[:ToUserName],
                                                                                 Content: reply_message_rule.reply_message
                        when "news"
                          weixin_news = ::EricWeixin::News.find_by_match_key reply_message_rule.reply_message
                          ::EricWeixin::ReplyMessage::get_reply_user_message_image_text ToUserName: receive_message[:FromUserName],
                                                                                        FromUserName: receive_message[:ToUserName],
                                                                                        news: weixin_news.weixin_articles
                        when "wx_function"
                          ::Weixin::WeixinAutoReplyFunctions.send(reply_message_rule.reply_message, ({:key_word => wx_key_word, :receive_message => receive_message}))
                      end
                    end
                  end
      reply_msg
    end


    # 获取提示找客服的语句。
    def get_contact_customer_notice public_account_id
      rules = ::EricWeixin::ReplyMessageRule.valid.where weixin_public_account_id: public_account_id,
                                                         key_word_type: 'text',
                                                         key_word: 'CONTACT_CUSTOMER_NOTICE'
      if rules.blank?
        ::EricWeixin::ReplyMessageRule.create_reply_message_rule weixin_public_account_id: public_account_id,
                                                                 key_word: 'CONTACT_CUSTOMER_NOTICE',
                                                                 reply_message: '请发送："芝麻开门"来联系客服',
                                                                 key_word_type: 'text',
                                                                 order: 1,
                                                                 reply_type: "text"

        ::EricWeixin::ReplyMessageRule.create_reply_message_rule weixin_public_account_id: public_account_id,
                                                                 key_word: '芝麻开门',
                                                                 reply_message: 'CONTACT_CUSTOMER_NOTICE',
                                                                 key_word_type: 'text',
                                                                 order: 1,
                                                                 reply_type: "text"

        return ::EricWeixin::ReplyMessageRule.get_contact_customer_notice public_account_id
      else
        rules.first.reply_message
      end
    end
  end
end
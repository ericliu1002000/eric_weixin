module EricWeixin
  #用于给普通用户回复消息。
  module ReplyMessage
    # 获取<b>被动回复</b>消息的数据格式。类型为：<b>图文消息</b>.
    # 一般用于用户发消息后，使用返回消息的方式向用户进行图文回复。
    # ===参数说明
    # * ToUserName: 收取方的账号
    # * FromUserName: 开发者账号
    # * news: 文章列表，EricWeixin::Article 的实例数组
    # ===示例
    # Tools::EricWeixin::ReplyMessage::get_reply_user_message_image_text ToUserName: 'xx',
    #                                                                    FromUserName: 'yy',
    #                                                                    news:[EricWeixin::ArticleData.new]
    def self.get_reply_user_message_image_text options
      xml = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.send(:xml) {
          xml.ToUserName { xml.cdata options[:ToUserName] }
          xml.FromUserName { xml.cdata options[:FromUserName] }
          xml.CreateTime { xml.cdata Time.now.to_i }
          xml.MsgType { xml.cdata 'news' }
          xml.ArticleCount (options[:news]||[]).length
          xml.Articles {
            options[:news].each do |news|
              xml.item {
                xml.Title { xml.cdata news.title }
                xml.Description { xml.cdata news.desc }
                xml.PicUrl { xml.cdata news.pic_url }
                xml.Url { xml.cdata news.link_url }
              }
            end
          }
        }
      end
      xml.to_xml
    end


    # 获取<b>被动回复</b>消息的数据格式。类型为：<b>文本消息</b> .
    # 一般用于用户发消息后，使用返回消息的方式向用户进行图文回复。
    # ===参数说明
    # * ToUserName: 收取方的账号
    # * FromUserName: 开发者账号
    # * Content: 回复的消息内容
    # ===示例
    # Tools::EricWeixin::ReplyMessage.get_reply_user_message_text ToUserName: 'xx',
    #                                                             FromUserName: 'yy',
    #                                                             Content: 'haha'

    def self.get_reply_user_message_text options
      xml = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.send(:xml) {
          xml.CreateTime { xml.cdata Time.now.to_i }
          xml.MsgType { xml.cdata 'text' }
          xml.ToUserName { xml.cdata options[:ToUserName] }
          xml.FromUserName { xml.cdata options[:FromUserName] }
          xml.Content { xml.cdata options[:Content] }
        }
      end
      xml.to_xml
    end

    # 用于将消息转发至多客服客户端.
    # ===参数说明
    # * ToUserName: 收取方的账号
    # * FromUserName: 开发者账号
    # ===示例
    # EricWeixin::ReplyMessage::transfer_mult_customer_service ToUserName: 'xxx',
    #                                                          FromUserName: 'yyyy'

    def self.transfer_mult_customer_service options
      xml = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.send(:xml) {
          xml.CreateTime { xml.cdata Time.now.to_i }
          xml.MsgType { xml.cdata 'transfer_customer_service' }
          xml.ToUserName { xml.cdata options[:ToUserName] }
          xml.FromUserName { xml.cdata options[:FromUserName] }
        }
      end
      xml.to_xml
    end
  end
end
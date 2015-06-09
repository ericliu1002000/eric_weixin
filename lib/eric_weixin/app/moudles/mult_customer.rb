#多客服模块
module EricWeixin::MultCustomer
  ##
  # 根据from_user, to_user等信息来获取<em>多客服</em>的数据日志。TODO 待完善
  # ===参数说明
  # ===调用说明
  def self.get_customer_service_messages options
    pa = if options[:weixin_public_account_id].blank?
           if options[:app_id].blank?
             pa = ::EricWeixin::PublicAccount.find_by_weixin_number options[:weixin_number]
             options[:app_id] = pa.weixin_app_id
             pa
           else
             ::EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
           end
         else
           ::EricWeixin::PublicAccount.find(options[:weixin_public_account_id])
         end
    BusinessException.raise '公众账号未查询到' if pa.blank?
    BusinessException.raise '没有指定用户。' if options[:openid].blank?
    endtime = options[:endtime].to_i
    openid = options[:openid]
    pageindex = options[:pageindex]
    pagesize = options[:pagesize].to_i
    pagesize = pagesize <= 0 ? 50 : pagesize > 50 ? 50 :pagesize
    starttime = options[:starttime].to_i
    post_data = {
        :endtime => endtime,
        :openid => openid,
        :pageindex => pageindex,
        :pagesize => pagesize,
        :starttime => starttime
    }
    token = ::EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: pa.weixin_app_id
    url = "https://api.weixin.qq.com/customservice/msgrecord/getrecord?access_token=#{token}"
    response = RestClient.post url, post_data.to_json
    response = JSON.parse response.body
    if response['errcode'] == 0
      record_list = response["recordlist"]
      unless record_list.blank?
        record_list.each do |record|
          record = record.merge(weixin_public_account_id: pa.id)
          ::EricWeixin::CustomsServiceRecord.create_one record unless ::EricWeixin::CustomsServiceRecord.exist_one record
        end
      else
        return response['errcode'], false
      end
    end
    return response['errcode'], true
  end


  # 发送多客服信息
  # ====参数说明
  # app_id: 微信公众账号app_id
  # openid: 接收消息用户的openid
  # message_type: 消息类型：包含以下：text image voice video music  news#
  # data: 值为一个hash， 对应着公众账号里要发送的内容，它的key为msgtype
  # message_id: 如果是回复消息，则把message_id传过来，用于日志记录。此参数可选。
  # weixin_number: 微信账号，与app_id二选一必填
  # ====调用方法
  # EricWeixin::MultCustomer.send_customer_service_message app_id: 'wx4564afc37fac0ebf',
  #                                                        openid: 'osyUtswoeJ9d7p16RdpC5grOeukQ',
  #                                                        message_type: 'text',
  #                                                        weixin_number: 'xxx'
  #                                                        data: {:content => 'hi, 客服消息来了'},

  # #
  def self.send_customer_service_message options
    pa =if options[:app_id].blank?
           pa = ::EricWeixin::PublicAccount.find_by_weixin_number options[:weixin_number]
           options[:app_id] = pa.weixin_app_id
           pa
         else
           ::EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
         end
    BusinessException.raise '公众账号未查询到' if pa.blank?
    token = ::EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: options[:app_id]


    post_data = {
        :touser => options[:openid],
        :msgtype => options[:message_type],
        options[:message_type] => options[:data]
    }
    url = "https://api.weixin.qq.com/cgi-bin/message/custom/send?access_token=#{token}"
    response = RestClient.post url, post_data.to_json
    response = JSON.parse response.body
    ::EricWeixin::MessageLog.transaction do
      message = ::EricWeixin::MessageLog.where(message_id: options[:message_id]).first
      message_id = if message.blank? then
                     nil
                   else
                     message.id
                   end
      ::EricWeixin::MessageLog.create_public_account_send_message_log openid: options[:openid],
                                                                      message_type: options[:message_type],
                                                                      data: options[:data].to_json,
                                                                      process_status: 0,
                                                                      parent_id: message_id,
                                                                      weixin_public_account_id: pa.id
    end
    ''
  end
end
module EricWeixin::Pay
  def self.generate_prepay_id options
    required_field = %i(appid mch_id openid attach body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    query_options = {}
    required_field.each do |p|
      query_options[p] = options[p]
    end
    query_options[:nonce_str] = SecureRandom.uuid.tr('-', '')
    public_account = ::EricWeixin::PublicAccount.find_by_weixin_app_id(options[:appid])

    sign = generate_sign query_options, public_account.mch_key
    last_query_options = query_options
    last_query_options[:sign] = sign
    pay_load = "<xml>#{last_query_options.map { |k, v| "<#{k.to_s}>#{v.to_s}</#{k.to_s}>" }.join}</xml>"
    require 'rest-client'

    response = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', pay_load
    pp "**********************下单结果 *********************************"
    pp response.force_encoding("UTF-8")
    result = Hash.from_xml(response.force_encoding("UTF-8"))
    return result['xml']['prepay_id'] if result['xml']['return_code'] == 'SUCCESS'
    nil
  end

  def self.generate_sign options, api_key
    query = options.sort.map do |k,v|
      "#{k.to_s}=#{v.to_s}"
    end.join('&')
    Digest::MD5.hexdigest("#{query}&key=#{api_key}").upcase
  end

  # wxappid
  # re_openid
  # total_amount
  # wishing
  # client_ip
  # act_name
  # remark
  def self.sendredpack options
    options[:nonce_str] = SecureRandom.uuid.tr('-', '')
    options[:total_num] = 1
    # 确认公众账号
    public_account = ::EricWeixin::PublicAccount.find_by_weixin_app_id(options[:wxappid])
    options[:mch_id] = public_account.mch_id
    options[:mch_billno] = public_account.mch_id + Time.now.strftime("%Y%m%d") + Time.now.strftime("%H%M%S") + EricTools.generate_random_string(4,1).to_s
    options[:send_name] = public_account.name
        # 生成签名
    sign = generate_sign options, public_account.mch_key
    options[:sign] = sign
    # 生成xml数据包
    pay_load = "<xml>#{options.map { |k, v| "<#{k.to_s}>#{v.to_s}</#{k.to_s}>" }.join}</xml>"
    require 'rest-client'
    # 请求接口
    # response = RestClient.post 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack', pay_load
    # RestClient::Resource.new(
    #     :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("/Users/ericliu/Desktop/cert/apiclient_cert.pem")),
    #     :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("/Users/ericliu/Desktop/cert/apiclient_key.pem"), "passphrase, if any"),
    #     :ssl_ca_file      =>  "/Users/ericliu/Desktop/cert/rootca.pem",
    #     :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
    # ).post 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack', pay_load

    response = RestClient::Request.execute(method: :post, url: 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack',
                                # ssl_ca_file: '/Users/beslow/Downloads/cert/apiclient_key.pem',
                                ssl_client_cert: OpenSSL::X509::Certificate.new(File.read("/Users/ericliu/Desktop/cert/apiclient_cert.pem")),
                                ssl_client_key:  OpenSSL::PKey::RSA.new(File.read("/Users/ericliu/Desktop/cert/apiclient_key.pem"), "passphrase, if any"),
                                ssl_ciphers: 'AESGCM:!aNULL',
    payload: pay_load)




    # 分析请求结果
    pp "********************** 发红包 请求结果 ******************************"
    pp response.force_encoding("UTF-8")
    result = Hash.from_xml(response.force_encoding("UTF-8"))
    return true if result['xml']['return_code'] == 'SUCCESS'
    false
  end
end
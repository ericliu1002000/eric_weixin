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
end
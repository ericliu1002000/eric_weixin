module Ip

  # 判断给定 ip 是否是正确的微信服务器 ip.
  # ===参数说明
  # * ip   # ip地址
  # * public_account_id   #公众号 id
  # ===调用示例
  # Ip.is_ip_exist? ip: "127.0.0.1", public_account_id: 1
  def self.is_ip_exist? options
    if $ip_list[options[:ip]] == true
      return true
    end
    Ip.get_ip_list public_account_id: options[:public_account_id]
    return $ip_list[options[:ip]] == true
  end

  private
    # 根据公众号 ID 获取微信服务器 IP 列表.
    # ===参数说明
    # * public_account_id   #公众账号 ID
    # ===调用示例
    # EricWeixin::Ip.get_ip_list public_account_id: 1
    def self.get_ip_list options
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: options[:public_account_id]
      ips = RestClient.get "https://api.weixin.qq.com/cgi-bin/getcallbackip?access_token=#{token}"
      ips = JSON.parse ips.body
      ips = ips["ip_list"]
      $ip_list.clear
      ips.each do |ip|
        $ip_list[ip] = true
      end
    end
end
module EricWeixin::Ip
  
  IPLIST = {:update_at => '2015-03-08 00:00:00', :iplist => ["101.226.62.77","101.226.62.78","101.226.62.79","101.226.62.80","101.226.62.81","101.226.62.82","101.226.62.83","101.226.62.84","101.226.62.85","101.226.62.86","101.226.103.59","101.226.103.60","101.226.103.61","101.226.103.62","101.226.103.63","101.226.103.69","101.226.103.70","101.226.103.71","101.226.103.72","101.226.103.73","140.207.54.73","140.207.54.74","140.207.54.75","140.207.54.76","140.207.54.77","140.207.54.78","140.207.54.79","140.207.54.80","182.254.11.203","182.254.11.202","182.254.11.201","182.254.11.200","182.254.11.199","182.254.11.198"]}

  # 判断给定 ip 是否是正确的微信服务器 ip.
  # ===参数说明
  # * ip   # ip地址
  # * public_account_id   #公众号 id
  # ===调用示例
  # Ip.is_ip_exist? ip: "127.0.0.1", public_account_id: 1
  def self.is_ip_exist? options
    options[:ip].to_s.to_debug
    return true if IPLIST[:iplist].include? options[:ip]
    get_ip_list options
    return true if IPLIST[:iplist].include? options[:ip]
    return false
  end

  private
    # 根据公众号 ID 获取微信服务器 IP 列表.
    # ===参数说明
    # * public_account_id   #公众账号 ID
    # ===调用示例
    # EricWeixin::Ip.get_ip_list public_account_id: 1
    def self.get_ip_list options
      return if IPLIST[:update_at] > 1.minutes.ago
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: options[:public_account_id]
      ips = RestClient.get "https://api.weixin.qq.com/cgi-bin/getcallbackip?access_token=#{token}"
      ips = JSON.parse ips.body
      IPLIST[:iplist] =  ips["ip_list"]
      IPLIST[:update_at] = Time.now
    end
end
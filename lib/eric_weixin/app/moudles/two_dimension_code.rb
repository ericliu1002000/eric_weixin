# 二维码
module EricWeixin::TwoDimensionCode
  # 长URL转短URL
  # ===参数说明：
  # * app_id 微信公众账号的app_id
  # * url 需要转短url的链接
  # ===调用示例：
  #  EricWeixin::TwoDimensionCode.short_url app_id: 'wx4564afc37fac0ebf', url: 'http://mp.weixin.qq.com/wiki/10/165c9b15eddcfbd8699ac12b0bd89ae6.html'
  def self.short_url options
    access_token = EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: options[:app_id]
    url = "https://api.weixin.qq.com/cgi-bin/shorturl?access_token=#{access_token}"
    pp url
    response = RestClient.post url, {action: "long2short", long_url: options[:url]}
    response = JSON.parse(response.body)
    pp response
    response["short_url"]
  end
end

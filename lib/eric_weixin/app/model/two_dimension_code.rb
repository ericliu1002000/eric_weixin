class EricWeixin::TwoDimensionCode < ActiveRecord::Base
  self.table_name = "weixin_two_dimension_codes"
  validates_uniqueness_of :scene_str, :allow_blank => true, :message => "永久二维码健值重复", if: Proc.new { |code| code.action_name == 'QR_LIMIT_STR_SCENE' }
  validates_presence_of :scene_str, message: '永久二维码健值不能为空。', if: Proc.new { |code| code.action_name == 'QR_LIMIT_STR_SCENE' }
  validate :check_scene_str_length

  def check_scene_str_length
    return if self.scene_str.blank?
    BusinessException.raise '永久性二维码场景值不能超过64位' if self.scene_str.length
  end

  def encode_ticket
    CGI::escape(self.ticket)
  end

  def image_url
    "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{self.encode_ticket}"
  end

  # 获取永久性二维码对象。
  # 典型使用场景如下：
  # 1.第一步调用此方法先创建/获取二维码对象。
  # 2.使用二维码对象获取二维码下载、展示链接。 如：two_dimension_code.image_url
  # 3.尽情享受带参数的永久二维码吧，很简单，有木有？
  # ===参数描述：
  # * app_id 微信app_id
  # * scene_str 场景值，字符串长度不能超过64位,亦不能为空。
  # * action_info 场景值描述（可选）
  # 调用示例：
  #  EricWeixin::TwoDimensionCode.get_long_time_two_dimension_code app_id: '5f1d945e9e7ffd6895a97c33190e9106', scene_str: 'abc', action_info: 'hello'
  #  EricWeixin::TwoDimensionCode.get_long_time_two_dimension_code app_id: '5f1d945e9e7ffd6895a97c33190e9106', scene_str: 'bus'
  def self.get_long_time_two_dimension_code options
    BusinessException.raise '场景值不能为空' if options[:scene_str].blank?
    BusinessException.raise '场景值不能超过64字符' if options[:scene_str].length > 63
    EricWeixin::TwoDimensionCode.transaction do
      public_account = EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
      BusinessException.raise 'app_id不存在' if public_account.blank?
      codes = public_account.two_dimension_codes.where scene_str: options[:scene_str],
                                                       action_name: "QR_LIMIT_STR_SCENE"
      code = if codes.blank?
               code = EricWeixin::TwoDimensionCode.new weixin_public_account_id: public_account.id,
                                                       action_name: "QR_LIMIT_STR_SCENE",
                                                       action_info: options[:action_info],
                                                       scene_str: options[:scene_str],
                                                       expire_at: Time.now.chinese_format
               code.save!
               code
             else
               codes[0]
             end
      token = ::EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: options[:app_id]
      url = "https://api.weixin.qq.com/cgi-bin/qrcode/create?access_token=#{token}"
      json = {:action_name => 'QR_LIMIT_STR_SCENE',
              :action_info => {
                  :scene => {
                      :scene_str => options[:scene_str]
                  }
              }}.to_json
      response = RestClient.post url, json
      response = JSON.parse response.body
      pp response
      code.ticket = response["ticket"]
      code.url = response["url"]
      code.save!
      code
    end
  end

  # 长URL转短URL
  # ===参数说明：
  # * app_id 微信公众账号的app_id
  # * url 需要转短url的链接
  # ===调用示例：
  #  EricWeixin::TwoDimensionCode.short_url app_id: '5f1d945e9e7ffd6895a97c33190e9106', url: 'http://mp.weixin.qq.com/wiki/10/165c9b15eddcfbd8699ac12b0bd89ae6.html'
  def self.short_url options
    access_token = EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: options[:app_id]
    url = "https://api.weixin.qq.com/cgi-bin/shorturl?access_token=#{access_token}"
    pp url
    response = RestClient.post url, {action: "long2short", long_url: options[:url]}.to_json
    response = JSON.parse(response.body)
    pp response
    response["short_url"]
  end

end

# EricWeixin::TwoDimensionCode.get_long_time_two_dimension_code app_id: '5f1d945e9e7ffd6895a97c33190e9106', scene_str: 'abc', action_info: 'hello'

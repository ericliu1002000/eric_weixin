class EricWeixin::MediaResource < ActiveRecord::Base

  self.table_name = 'weixin_media_resources'


  #保存图文内图片
  # ===参数说明
  # * public_account_id  需要处理的公众账号
  # * pic   图片
  # * tags   标签
  # ===调用示例
  #
  # ::EricWeixin::MediaResource.save_pic_in_article pic: File.read('/Users/ericliu/Pictures/1.pic.jpg'),
  #                                                 tags: 'test',
  #                                                 public_account_id: 1
  #
  # #
  def self.save_pic_in_article options
    EricWeixin::MediaResource.transaction do
      pp options[:pic].methods
      resource = EricWeixin::MediaResource.new tags: options[:tags],
                                               category_name: 'pic_in_article'
      resource.save!

      url = EricWeixin::MediaResource.upload_pic_in_article pic: options[:pic],
                                                            public_account_id: options[:public_account_id]
      resource.wechat_link = url
      resource.save!


      file_name = "#{EricTools.uuid}-#{options[:pic].original_filename}"
      origin_name_with_path = Rails.root.join('public/uploads/wechat_pic/', file_name)
      File.open(origin_name_with_path, 'wb') do |file|
        file.write(uploaded_io.read)
      end

      resource.local_link = "/uploads/wechat_pic/#{file_name}"
      resource.save!

    end
  end


  # 上传图文内图片.
  # ===参数说明
  # * pic 图片文件。
  # * public_account_id 公众账号id
  # ===调用示例
  # ::EricWeixin::MediaResource.upload_pic_in_article pic: File.read('/user/root/xx.jpg'),
  #                                                   id: 1
  def self.upload_pic_in_article options
    token = ::EricWeixin::AccessToken.get_new_token options[:public_account_id]
    url = "https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token=#{token}"
    response = RestClient.post url, :media => options[:pic]
    url = JSON.parse(response)["url"]
  end

end


class EricWeixin::MediaResource < ActiveRecord::Base

  self.table_name = 'weixin_media_resources'

  has_many :media_articles, foreign_key: 'thumb_media_id'

  RESOURCE_TYPE = {
      'pic_in_article' => '文章内图片',
      'thumbnail' => '缩略图',
      'audio' => '音频',
      'video' => '视频'
  }

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
  # #
  def self.save_pic_in_article options, file
    pic_in_article_path = '/uploads/wechat_pic/file_in_content/'
    unless Dir.exist?  Rails.root.join("public").to_s + pic_in_article_path
      BusinessException.raise "请创建目录#{ Rails.root.join("public").to_s + pic_in_article_path}"
    end
    EricWeixin::MediaResource.transaction do
      # pp options[:pic].methods
      resource = EricWeixin::MediaResource.new tags: options[:tags],
                                               category_name: 'pic_in_article',
                                               public_account_id: options[:public_account_id]
      resource.save!


      file_name = "#{EricTools.uuid}-#{file.original_filename}"
      origin_name_with_path = Rails.root.join("public#{pic_in_article_path}", file_name)
      File.open(origin_name_with_path, 'wb') do |f|
        f.write(file.read)
      end

      url = EricWeixin::MediaResource.upload_pic_in_article pic: File.new(origin_name_with_path),
                                                            public_account_id: options[:public_account_id]

      resource.wechat_link = url
      resource.local_link = "#{pic_in_article_path}#{file_name}"
      resource.save!

    end
  end


  # 上传图文内图片.
  # ===参数说明
  # * pic 图片文件。
  # * public_account_id 公众账号id
  # ===调用示例
  # ::EricWeixin::MediaResource.upload_pic_in_article pic: File.new('/Users/ericliu/Pictures/1.pic.jpg'),
  #                                                   public_account_id: 1
  def self.upload_pic_in_article options
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: options[:public_account_id]
    url = "https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token=#{token}"
    response = RestClient.post url, :media => options[:pic]
    response_json = JSON.parse(response)
    url = response_json["url"]
    BusinessException.raise response_json["errmsg"] if url.blank?
    url
  end


  #保存图文内图片
  # ===参数说明
  # * public_account_id  需要处理的公众账号
  # * media   资源
  # * tags   标签
  # * type  资源类型
  # ===调用示例
  #
  # ::EricWeixin::MediaResource.save_media media: File.new('/Users/ericliu/Pictures/1.pic.jpg'),
  #                                        tags: 'test',
  #                                        public_account_id: 1,
  #                                        type: xx
  # #
  def self.save_media options, file
    BusinessException.raise "媒体类型不正确" unless EricWeixin::MediaResource::RESOURCE_TYPE.keys.include?(options[:type])
    file_path = "/uploads/wechat_pic/#{options[:type]}/"
    unless Dir.exist?  Rails.root.join("public").to_s + file_path
      BusinessException.raise "请创建目录#{ Rails.root.join("public").to_s + file_path}"
    end
    EricWeixin::MediaResource.transaction do
      resource = EricWeixin::MediaResource.new tags: options[:tags],
                                               category_name: options[:type],
                                               public_account_id: options[:public_account_id]
      resource.save!

      file_name = "#{EricTools.uuid}-#{file.original_filename}"
      origin_name_with_path = Rails.root.join("public#{file_path}", file_name)
      File.open(origin_name_with_path, 'wb') do |f|
        f.write(file.read)
      end


      json = EricWeixin::MediaResource.upload_media media: File.new(origin_name_with_path),
                                                   type: case options[:type]
                                                           when 'thumbnail'
                                                             'thumb'
                                                           when 'audio'
                                                             'voice'
                                                           when 'video'
                                                             'video'
                                                           when 'image'
                                                             'image'
                                                         end,
                                                   public_account_id: options[:public_account_id],
                                                    file_name: file_name
      url = json["url"]
      media_id = json["media_id"]
      resource.local_link = "#{file_path}#{file_name}"
      resource.wechat_link = url
      resource.media_id = media_id
      resource.save!


    end
  end


  # 上传永久性素材.
  # ===参数说明
  # * media 图片文件。
  # * type 素材类型：包含以下：image  voice  video  thumb
  # * public_account_id 公众账号id
  # ===调用示例
  # ::EricWeixin::MediaResource.upload_media media: File.new('/Users/ericliu/Pictures/1.pic.jpg'),
  #                                          public_account_id: 1,
  #                                          type: 'image'

  def self.upload_media options
    BusinessException.raise '资源类型不正确，应该是image  voice  video  thumb 的其中一种' unless ["image", "voice", "video", "thumb"].include? options[:type]
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: options[:public_account_id]
    url = "https://api.weixin.qq.com/cgi-bin/material/add_material?access_token=#{token}"

    post_data = {:media => options[:media], :type => options[:type]}
    if options[:type] == 'media'
      post_data[:description] = {"title"=>options[:file_name], "introduction"=>"INTRODUCTION"}.to_json
    end
    response = RestClient.post url, post_data
    pp response
    response_json = JSON.parse(response)
    BusinessException.raise response_json["errmsg"] unless response_json["errmsg"].blank?
    response_json
  end

  def delete_server_resource
    EricWeixin::MediaResource.transaction do
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
      url = "https://api.weixin.qq.com/cgi-bin/material/del_material?access_token=#{token}"

      response = RestClient.post url, { "media_id" => self.media_id }.to_json
      pp "****************** 删除该图文 ***********************"
      pp response
      response_json = JSON.parse(response)
      BusinessException.raise response_json["errmsg"] unless response_json["errcode"] == 0
      self.media_id = nil
      self.save!
    end
  end

  def delete_self
    BusinessException.raise '该资源有其他文章素材引用，不能删除。' unless self.media_articles.blank?
    self.delete_server_resource
    self.destroy!
  end
end


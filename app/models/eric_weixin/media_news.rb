class EricWeixin::MediaNews < ActiveRecord::Base
  self.table_name = 'weixin_media_news'
  has_many :media_article_news, foreign_key: 'weixin_media_news_id'
  has_many :media_articles, through: :media_article_news
  # def upload_news_old
  #
  #   EricWeixin::MediaNews.transaction do
  #     h = {"articles" => []}
  #     pp "************* 图文 **************"
  #     pp self
  #     pp "************** 该图文包含的文章 *******************"
  #     pp self.media_articles
  #     self.media_articles.each do |article|
  #       article_hash = {
  #           "title" => article.title,
  #           "thumb_media_id" => article.media_resource.media_id,
  #           "author" => article.author,
  #           "content_source_url" => article.content_source_url,
  #           "content" => CGI::escape(article.content).force_encoding("UTF-8"),
  #           "digest" => article.digest,
  #           "show_cover_pic" => if article.show_cover_pic then 1 else 0 end
  #       }
  #       pp "*************** 文章内容 **********************"
  #       pp article_hash
  #       h["articles"] << article_hash
  #     end
  #
  #     token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
  #     url = "https://api.weixin.qq.com/cgi-bin/media/uploadnews?access_token=#{token}"
  #     response = RestClient.post url, CGI::unescape(h.to_json)
  #     pp "********************* 上传该图文 **********************"
  #     pp response
  #     response_json = JSON.parse(response)
  #     BusinessException.raise response_json["errmsg"] unless response_json["errmsg"].blank?
  #     self.media_id = response_json["media_id"]
  #     self.save!
  #     self.reload
  #   end
  # end

  def upload_news
    EricWeixin::MediaNews.transaction do
      h = {"articles" => []}
      pp "************* 图文 **************"
      pp self
      pp "************** 该图文包含的文章 *******************"
      pp self.media_articles
      self.media_articles.each do |article|
        article_hash = {
            "title" => article.title,
            "thumb_media_id" => article.media_resource.media_id,
            "author" => article.author,
            "content_source_url" => article.content_source_url,
            "content" => CGI::escape(article.content.gsub("\"","'")),
            "digest" => article.digest,
            "show_cover_pic" => if article.show_cover_pic then 1 else 0 end
        }
        pp "*************** 文章内容 **********************"
        pp article_hash
        h["articles"] << article_hash
      end

      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
      url = "https://api.weixin.qq.com/cgi-bin/material/add_news?access_token=#{token}"
      pp "***************************** CGI::unescape(h.to_json) ********************************"
      pp CGI::unescape(h.to_json)
      response = RestClient.post url, CGI::unescape(h.to_json)
      pp "********************* 上传该图文 **********************"
      pp response
      response_json = JSON.parse(response)
      BusinessException.raise response_json.to_s if response_json["media_id"].blank?
      self.media_id = response_json["media_id"]
      self.save!
      self.reload
    end
  end

  def delete_server_news
    EricWeixin::MediaNews.transaction do
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
      url = "https://api.weixin.qq.com/cgi-bin/material/del_material?access_token=#{token}"

      response = RestClient.post url, { "media_id" => self.media_id }.to_json
      pp "****************** 删除该图文 ***********************"
      pp response
      pp JSON.parse(response)["errcode"].class
      response_json = JSON.parse(response)
      BusinessException.raise response_json["errmsg"] unless response_json["errcode"] == 0
      self.media_id = nil
      self.save!
      self.reload
    end
  end

  def self.try_send_media_news
    not_send_media_news = self.where(status: 0)
    not_send_media_news.each do |news|
      next if news.planned_send_time.blank?
      news.send_to_openids if news.planned_send_time <= Time.now
    end
  end

  def send_to_openids
    BusinessException.raise '' if self.media_id.blank?
    EricWeixin::MediaNews.transaction do
      openids = ::Weixin::Process.__send__ self.user_group_name
      pp "****************** 将要发送的openids *********************"
      pp openids
      1.upto(100000).each do |i|
        start_number = i*10000 - 10000
        end_number = i*10000-1
        needopenids = openids[start_number..end_number]
        break if needopenids.blank?
        token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
        url = "https://api.weixin.qq.com/cgi-bin/message/mass/send?access_token=#{token}"
        data = {
            "touser" => needopenids,
            "mpnews" => {"media_id" => self.media_id},
            "msgtype" => "mpnews"
        }
        pp "************************* 群发的参数 *******************************"
        pp data
        response = RestClient.post url, data.to_json
        pp "******************* 群发的结果 ******************************"
        pp response
        response_json = JSON.parse(response)
        BusinessException.raise response_json["errmsg"] unless response_json["errcode"] == 0
      end
      self.status = 1
      self.save!
      self.reload
    end
  end

  def preview openid
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.public_account_id
    url = "https://api.weixin.qq.com/cgi-bin/message/mass/preview?access_token=#{token}"
    response = RestClient.post url, {
                           "touser" => openid,
                           "mpnews" => {"media_id" => self.media_id},
                           "msgtype" => "mpnews"
                       }.to_json
    pp "********************* 预览结果 ****************************"
    pp response
    response_json = JSON.parse(response)
    BusinessException.raise response_json["errmsg"] unless response_json["errcode"] == 0
  end

  # will_send_article_msg: will_send_article_msg,
  # user_group_name: user_group_name,
  # send_at_fixed_time: send_at_fixed_time,
  # send_fixed_date: send_fixed_date,
  # send_fixed_time: send_fixed_time,
  # send_save_to_history: send_save_to_history
  def self.save_news options
    options = get_arguments_options options, [:will_send_article_msg, :user_group_name,
                                              :send_at_fixed_time, :send_fixed_date,
                                              :send_fixed_time, :send_save_to_history,
                                              :public_account_id]
    transaction do
      news = new
      if options[:send_at_fixed_time] == 'true'
        news.planned_send_time = "#{options[:send_fixed_date]} #{options[:send_fixed_time]}"
      end
      news.user_group_name = options[:user_group_name]
      news.status = 0
      news.public_account_id = options[:public_account_id]
      news.save!
      article_ids = options[:will_send_article_msg].split(',')
      article_ids.each_with_index do |id, index|
        a_n = ::EricWeixin::MediaArticleNews.new
        a_n.sort = index
        article = ::EricWeixin::MediaArticle.find_by_id(id)
        a_n.media_article = article
        a_n.media_news = news
        a_n.save!
      end
      news.upload_news
      news
    end
  end

  def update_news options
    options = ::EricWeixin::MediaNews.get_arguments_options options, [:will_send_article_msg, :user_group_name,
                                              :send_at_fixed_time, :send_fixed_date,
                                              :send_fixed_time, :send_save_to_history,
                                              :public_account_id]
    ::EricWeixin::MediaNews.transaction do
      news = self
      if options[:send_at_fixed_time] == 'true'
        news.planned_send_time = "#{options[:send_fixed_date]} #{options[:send_fixed_time]}"
      end
      news.user_group_name = options[:user_group_name]
      news.public_account_id = options[:public_account_id]
      news.save!

      # 清空图文与文章的关联
      news.media_articles = []

      article_ids = options[:will_send_article_msg].split(',')
      article_ids.each_with_index do |id, index|
        a_n = ::EricWeixin::MediaArticleNews.new
        a_n.sort = index
        article = ::EricWeixin::MediaArticle.find_by_id(id)
        a_n.media_article = article
        a_n.media_news = news
        a_n.save!
      end
      news.reload
      news.delete_server_news
      news.upload_news
      news
    end
  end

end

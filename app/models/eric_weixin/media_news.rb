class EricWeixin::MediaNews < ActiveRecord::Base
  self.table_name = 'weixin_media_news'
  has_many :media_article_news, foreign_key: 'weixin_media_news_id'
  has_many :media_articles, through: :media_article_news
  def upload_news
    EricWeixin::MediaNews.transaction do
      h = {"articles" => []}
      self.media_articles.each do |article|
        article_hash = {
            "title" => article.title,
            "thumb_media_id" => article.thumb_media_id,
            "author" => article.author,
            "content_source_url" => article.content_source_url,
            "content" => article.content,
            "digest" => article.digest,
            "show_cover_pic" => if article.show_cover_pic then 1 else 0 end
        }
        h["articles"] << article_hash
      end

      token = ::EricWeixin::AccessToken.get_new_token self.public_account_id
      url = "https://api.weixin.qq.com/cgi-bin/media/uploadnews?access_token=#{token}"
      response = RestClient.post url, h
      response_json = JSON.parse(response)
      self.media_id = response_json["media_id"]
      self.save!
    end
  end


  def send_to_openids
    BusinessException.raise '' if self.media_id.blank?
    EricWeixin::MediaNews.transaction do
      openids = ::Weixin::Process.__send__ self.user_group_name
      1.upto(100000).each do |i|
        start_number = i*10000 - 10000
        end_number = i*10000-1
        needopenids = openids[start_number..end_number]
        break if needopenids.blank?
        token = ::EricWeixin::AccessToken.get_new_token self.public_account_id
        url = "https://api.weixin.qq.com/cgi-bin/message/mass/send?access_token=#{token}"
        RestClient.post url, {
                               "touser" => needopenids,
                               "mpnews" => {"media_id" => self.media_id},
                               "msgtype" => "mpnews"
                           }
      end
      self.status = 'send'
      self.save!
    end
  end

  def preview openid
    token = ::EricWeixin::AccessToken.get_new_token self.public_account_id
    url = "https://api.weixin.qq.com/cgi-bin/message/mass/preview?access_token=#{token}"
    RestClient.post url, {
                           "touser" => openid,
                           "mpnews" => {"media_id" => self.media_id},
                           "msgtype" => "mpnews"
                       }
  end
end

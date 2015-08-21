class EricWeixin::MediaNews < ActiveRecord::Base
  self.table_name = 'weixin_media_news'
  has_many :media_article_news, foreign_key: 'weixin_media_news_id'
  has_many :media_articles, through: :media_article_news





  def upload_news
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

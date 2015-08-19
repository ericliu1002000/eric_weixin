class EricWeixin::MediaNews < ActiveRecord::Base
  self.table_name = 'weixin_media_news'
  has_many :media_article_news, foreign_key: 'weixin_media_news_id'
  has_many :media_articles, through: :media_article_news

end

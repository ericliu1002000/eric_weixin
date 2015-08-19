class EricWeixin::MediaArticle < ActiveRecord::Base
  self.table_name = 'weixin_media_articles'
  has_many :media_article_news, foreign_key: 'weixin_media_article_id'
  has_many :media_news, through: :media_article_news

end

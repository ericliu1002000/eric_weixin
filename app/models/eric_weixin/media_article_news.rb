class EricWeixin::MediaArticleNews < ActiveRecord::Base
  self.table_name = 'weixin_media_articles_news'
  belongs_to :media_article, foreign_key: 'weixin_media_article_id'
  belongs_to :media_news, foreign_key: 'weixin_media_news_id'

end

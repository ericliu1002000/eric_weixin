class EricWeixin::ArticleNews < ActiveRecord::Base
  self.table_name = 'weixin_article_news'
  belongs_to :weixin_article, :class_name => '::EricWeixin::Article', :foreign_key => 'weixin_article_id'
  belongs_to :weixin_newses, :class_name => '::EricWeixin::News', :foreign_key => 'weixin_news_id'
  accepts_nested_attributes_for :weixin_newses


end

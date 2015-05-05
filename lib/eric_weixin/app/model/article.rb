class EricWeixin::Article < ActiveRecord::Base
  self.table_name = "weixin_articles"
  validates_presence_of :title, :pic_url, :link_url
  has_many :weixin_article_newses, :class_name => '::EricWeixin::ArticleNews', foreign_key: "weixin_article_id"
  has_many :weixin_news_datas, :class_name => '::EricWeixin::NewsData', through: :weixin_article_newses


  class << self
    def create_article_data options
      ::EricWeixin::Article.transaction do
        article = ::EricWeixin::Article.new(options)
        article.save!
        article
      end
    end
  end
end

class EricWeixin::News < ActiveRecord::Base
  self.table_name = "weixin_news"
  has_many :weixin_article_newses, :class_name => '::EricWeixin::ArticleNews', foreign_key: "weixin_news_id"
  has_many :weixin_articles, -> { order "sort" }, :class_name => '::EricWeixin::Article', through: :weixin_article_newses



  def generate_news_data
    articles = []
    self.weixin_articles.each do |article_data|
      article = generate_article(article_data.title, article_data.desc, article_data.pic_url, article_data.link_url)
      articles << article
    end
    articles
  end

  class << self
    def create_news_datas(options, weixin_article_data_ids, weixin_article_data_sort)
      ::EricWeixin::News.transaction do
        news_data = ::EricWeixin::News.new
        news_data.update_attributes(options)
        news_data.weixin_articles.clear
        weixin_article_data_ids.each do |article_data_id|
          article_data = ::EricWeixin::Article.find(article_data_id)
          if (!article_data.blank?) && (!news_data.weixin_articles.include?(article_data))
            ::EricWeixin::ArticleNews.create! weixin_article_id: article_data_id, weixin_news_id: news_data.id, sort: weixin_article_data_sort[article_data_id].first
          end
        end
        news_data.save!
        news_data
      end
    end


    def update_news_datas(id, options, weixin_article_data_ids, weixin_article_data_sort)
      ::EricWeixin::News.transaction do
        news_data = ::EricWeixin::News.find(id)
        news_data.update(options)
        news_data.weixin_articles.clear
        weixin_article_data_ids.each do |article_data_id|
          article_data = ::EricWeixin::Article.find(article_data_id)
          if (!article_data.blank?) && (!news_data.weixin_articles.include?(article_data))
            ::EricWeixin::ArticleNews.create! weixin_article_id: article_data_id, weixin_news_id: news_data.id, sort: weixin_article_data_sort[article_data_id].first
          end
        end
        news_data.save!
        news_data
      end

    end
  end
end

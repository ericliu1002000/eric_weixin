class EricWeixin::MediaArticle < ActiveRecord::Base
  self.table_name = 'weixin_media_articles'
  has_many :media_article_news, foreign_key: 'weixin_media_article_id'
  has_many :media_news, through: :media_article_news

  belongs_to :media_resource, foreign_key: 'thumb_media_id'

  validates_presence_of :thumb_media_id, message: '缩略图必须有。'
  validates_presence_of :title, message: '标题不能为空。'
  validates :title, length: { maximum: 64, message: "标题最长为64" }
  validates :author, length: { maximum: 8, message: "作者字数最大为8"}
  validates :digest, length: { maximum: 120, message: "摘要字数最大为120" }


  def self.create_media_article options
    options = get_arguments_options options, [:tag, :thumb_media_id, :author, :title,
                                              :digest, :show_cover_pic, :is_first_article,
                                              :content, :content_source_url, :public_account_id],
                                    show_cover_pic: true, is_first_article: false
    transaction do
      media_article = ::EricWeixin::MediaArticle.new options
      media_article.save!
      media_article
    end
  end

  def update_media_article options
    options = EricWeixin::MediaArticle.get_arguments_options options, [:tag, :thumb_media_id, :author, :title,
                                                                       :digest, :show_cover_pic, :is_first_article,
                                                                       :content, :content_source_url, :public_account_id]
    EricWeixin::MediaArticle.transaction do
      self.update! options
      self
    end
  end

  def self.common_query options
    articles = self.all
    articles = articles.where(public_account_id: options[:public_account_id]) unless options[:public_account_id].blank?
    articles = articles.where("weixin_media_articles.tag like ?", "%#{options[:tag]}%") unless options[:tag].blank?
    unless options[:start_date].blank?
      start_date = options[:start_date].to_time
      start_date = start_date.change(hour: 0, min:0, sec:0)
      articles = articles.where("weixin_media_articles.created_at >= ?", start_date)
    end
    unless options[:end_date].blank?
      end_date = options[:end_date].to_time
      end_date = end_date.change(hour: 23, min:59, sec:59)
      articles = articles.where("weixin_media_articles.created_at <= ?", end_date)
    end
    articles
  end
end

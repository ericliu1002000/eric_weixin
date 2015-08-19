class CreateWeixinMediaArticlesNews < ActiveRecord::Migration
  def change
    create_table :weixin_media_articles_news do |t|
      t.integer :weixin_media_article_id
      t.integer :weixin_media_news_id
      t.integer :sort
    end
  end
end

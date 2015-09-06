class EricWeixin::MediaNewsSentRecord < ActiveRecord::Base
  self.table_name = 'weixin_media_news_sent_records'
  belongs_to :media_news, foreign_key: 'media_news_id'


end
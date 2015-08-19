class EricWeixin::MediaResource < ActiveRecord::Base

  self.table_name = 'weixin_media_resources'

  RESOURCE_TYPE = {
      'pic_in_article' => '文章内图片',
      'thumbnail' => '缩略图',
      'audio' => '音频',
      'video' => '视频'
  }

end


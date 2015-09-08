class AddErrorCountToWeixinMediaNews < ActiveRecord::Migration
  def change
    add_column :weixin_media_news, :error_count, :integer
  end
end

class EricWeixin::Cms::Weixin::MediaNewsController < EricWeixin::Cms::BaseController
  def index

  end

  def new

  end

  def query_media_articles
    @media_articles = ::EricWeixin::MediaArticle.common_query params.permit(:tag, :start_date, :end_date, :public_account_id)
    @total_page = (@media_articles.count/4) + 1
    page = params[:page] || 1
    @media_articles = @media_articles.paginate(per_page: 4, page: page)
    @current_page = page.to_i
    render partial: 'select_article'
  end

  def query_weixin_users
    begin
      BusinessException.raise '请指定微信公众号。' if params[:public_account_id].blank?
      options = {}
      options[:weixin_public_account_id] = params[:public_account_id]
      options[:nickname] = params[:nickname]
      @weixin_users = ::EricWeixin::WeixinUser.where(weixin_public_account_id: params[:public_account_id])
      @weixin_users = @weixin_users.where("nickname like ?", "%#{CGI::escape(params[:nickname])}%") unless params[:nickname].blank?
      render partial: 'select_user'
    rescue Exception=>e
      dispose_exception e
      render text: "查询失败：#{get_notice_str}"
      return
    end
  end

  def will_send_articles

    articles = []
    ids_msg = []

    unless params[:existed_article_ids].blank?
      e_ids = params[:existed_article_ids].split(',')
      e_ids.each do |id|
        ma = ::EricWeixin::MediaArticle.find_by_id(id)
        articles << ma
        ids_msg << ma.id
      end
    end

    if params[:new_article_id].blank?
      # 处理调整顺序
      unless params[:up_article_id].blank?
        index = ids_msg.index(params[:up_article_id].to_i)
        if index==0
          render text: 'top'
          return
        else
          tmp_article = articles[index]
          articles[index] = articles[index-1]
          articles[index-1] = tmp_article
          tmp_id = ids_msg[index]
          ids_msg[index] = ids_msg[index-1]
          ids_msg[index-1] = tmp_id
        end
      else
        unless params[:down_article_id].blank?
          index = ids_msg.index(params[:down_article_id].to_i)
          if index==ids_msg.size-1
            render text: 'bottom'
            return
          else
            tmp_article = articles[index]
            articles[index] = articles[index+1]
            articles[index+1] = tmp_article
            tmp_id = ids_msg[index]
            ids_msg[index] = ids_msg[index+1]
            ids_msg[index+1] = tmp_id
          end
        end
      end
    else
      # 处理新增文章
      if ids_msg.include? params[:new_article_id].to_i
        # 文章已经存在
        render text: 'existed'
        return
      else
        nma = ::EricWeixin::MediaArticle.find_by_id(params[:new_article_id])
        articles << nma
        ids_msg << nma.id
      end
    end

    @will_send_articles = articles
    @will_send_article_msg = ids_msg.join(",")
    render partial: 'will_send_article'

  end

  def save_news
        # will_send_article_msg: will_send_article_msg,
        # user_group_name: user_group_name,
        # send_at_fixed_time: send_at_fixed_time,
        # send_fixed_date: send_fixed_date,
        # send_fixed_time: send_fixed_time,
        # send_save_to_history: send_save_to_history
        # public_account_id
    begin
      if params[:media_news_id].blank?
        media_news = ::EricWeixin::MediaNews.save_news params.permit(:will_send_article_msg,:user_group_name,
                                          :send_at_fixed_time,:send_fixed_date,
                                          :send_fixed_time,:send_save_to_history,:public_account_id)
        render text: "#{media_news.id}"
        return
      else
        media_news = ::EricWeixin::MediaNews.find_by_id(params[:media_news_id])
        media_news.update_news params.permit(:will_send_article_msg,:user_group_name,
                                             :send_at_fixed_time,:send_fixed_date,
                                             :send_fixed_time,:send_save_to_history,:public_account_id)
        render text: "#{media_news.id}"
      end
    rescue Exception=>e
      dispose_exception e
      render text: "保存失败: #{get_notice_str}"
    end
  end

  def preview
    begin
      if params[:media_news_id].blank?
        media_news = ::EricWeixin::MediaNews.save_news params.permit(:will_send_article_msg,:user_group_name,
                                                                     :send_at_fixed_time,:send_fixed_date,
                                                                     :send_fixed_time,:send_save_to_history,:public_account_id)
        media_news.preview params.permit(:preview_openid)[:preview_openid]
        render text: "#{media_news.id}"
        return
      else
        media_news = ::EricWeixin::MediaNews.find_by_id(params.permit(:media_news_id)[:media_news_id])
        media_news.update_news params.permit(:will_send_article_msg,:user_group_name,
                                             :send_at_fixed_time,:send_fixed_date,
                                             :send_fixed_time,:send_save_to_history,:public_account_id)
        media_news.preview params.permit(:preview_openid)[:preview_openid]
        render text: "#{media_news.id}"
      end
    rescue Exception=>e
      dispose_exception e
      render text: "保存失败||预览失败：#{get_notice_str}"
    end
  end

  def send_news_now
    begin
      if params[:media_news_id].blank?
        media_news = ::EricWeixin::MediaNews.save_news params.permit(:will_send_article_msg,:user_group_name,
                                                                     :send_at_fixed_time,:send_fixed_date,
                                                                     :send_fixed_time,:send_save_to_history,:public_account_id)
        media_news.send_to_openids
        render text: "#{media_news.id}"
        return
      else
        media_news = ::EricWeixin::MediaNews.find_by_id(params[:media_news_id])
        media_news.update_news params.permit(:will_send_article_msg,:user_group_name,
                                             :send_at_fixed_time,:send_fixed_date,
                                             :send_fixed_time,:send_save_to_history,:public_account_id)
        media_news.send_to_openids
        render text: "#{media_news.id}"
      end
    rescue Exception=>e
      dispose_exception e
      render text: "保存失败||立即发送失败：#{get_notice_str}"
    end
  end



end
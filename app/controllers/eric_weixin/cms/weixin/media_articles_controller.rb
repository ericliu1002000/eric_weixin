class EricWeixin::Cms::Weixin::MediaArticlesController < EricWeixin::Cms::BaseController


  def index
    @media_articles = ::EricWeixin::MediaArticle.all.order(:id)
    @media_articles = @media_articles.where("title like ?", "%#{params[:title]}%") unless params[:title].blank?
    @media_articles = @media_articles.paginate(per_page: params[:per_page]||10, page: params[:page]||1)
  end

  def new
    @media_article = ::EricWeixin::MediaArticle.new
    @current_page = 1
    @pics = available_pics
    @total_page = (@pics.count/perpage) +1
    @pics = @pics.paginate(per_page: perpage, page: 1)
  end

  def select_pic
    @pics = available_pics
    @total_page = (@pics.count/perpage) +1
    @pics = @pics.paginate(per_page: perpage, page: params[:target_page].to_i)
    @current_page = params[:target_page].to_i
    render partial: 'select_pic'
  end

  def create
    begin
      EricWeixin::MediaArticle.create_media_article media_article_params
      flash[:success] = '微信文章创建成功，再来一篇吧！'
      redirect_to action: :new
    rescue Exception=> e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to action: :new, session_content_id: set_session_content
    end
  end

  def edit
    @media_article = ::EricWeixin::MediaArticle.find_by_id(params[:id])
    @current_page = 1
    @pics = available_pics
    @total_page = (@pics.count/perpage) +1
  end

  def update
    begin
      media_article = EricWeixin::MediaArticle.find_by_id(params[:id])
      media_article.update_media_article media_article_params
      flash[:success] = '微信文章更新成功！'
      redirect_to action: :index
    rescue Exception=>e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to "/eric_weixin/cms/weixin/media_articles/#{params[:id]}/edit?session_content_id=#{set_session_content}"
    end
  end

  private

    def media_article_params
      params.require(:article).permit(:tag, :thumb_media_id, :author, :title,
                                      :digest, :show_cover_pic, :is_first_article,
                                      :content, :content_source_url, :public_account_id)
    end
    def perpage
      18
    end

    def available_pics
      ::EricWeixin::MediaResource.all.order(:id)
    end

end
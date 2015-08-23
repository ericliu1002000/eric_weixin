class EricWeixin::Cms::Weixin::MediaResourcesController < EricWeixin::Cms::BaseController

  def index
    @media_resources = ::EricWeixin::MediaResource.all.order(:id)
    @media_resources = @media_resources.where("tags like ?", "%#{params[:tag]}%") unless params[:tag].blank?
    @media_resources = @media_resources.where(category_name: params[:category_name]) unless params[:category_name].blank?
    @media_resources = @media_resources.paginate(per_page: params[:per_page]||10, page: params[:page]||1)
  end

  def new
    @media_resource = ::EricWeixin::MediaResource.new
  end

  def create
    begin
      p = params.require(:resource).permit(:tags, :category_name,  :public_account_id)
      params.permit :pic
      if p[:category_name] == 'pic_in_article'
        EricWeixin::MediaResource.save_pic_in_article p, params[:pic]
        flash[:success] = '创建成功'
        redirect_to action: :new
        return
      else
        p[:type] = p[:category_name]
        EricWeixin::MediaResource.save_media p, params[:pic]
        flash[:success] = '创建成功'
        redirect_to action: :new
        return
      end

    rescue Exception=> e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to action: :new, session_content_id: set_session_content
    end
  end

  def edit
    @media_resource = ::EricWeixin::MediaResource.find_by_id(params[:id])
  end

  def update
    begin

    rescue Exception=>e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to "/eric_weixin/cms/weixin/media_resources/#{params[:id]}/edit?session_content_id=#{set_session_content}"
    end
  end

end
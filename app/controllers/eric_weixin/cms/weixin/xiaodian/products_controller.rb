class EricWeixin::Cms::Weixin::Xiaodian::ProductsController < EricWeixin::Cms::BaseController
  def index
    @products = EricWeixin::Xiaodian::Product.all
    @products = @products.where("id >= ?", params[:start_id]) unless params[:start_id].blank?
    @products = @products.where("id <= ?", params[:end_id]) unless params[:end_id].blank?
    @products = @products.order(id: :desc).paginate(per_page: params[:per_page]||6, page: params[:page]||1)
  end

  def get_all_products
    EricWeixin::PublicAccount.all.each do |pb|
      EricWeixin::Xiaodian::Product.get_all_products pb.name
      EricWeixin::Xiaodian::Category.update_sku_info pb.name
    end
    redirect_to 'EricWeixin::Cms::Weixin::Xiaodian::Products#index'
  end


end
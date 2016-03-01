class EricWeixin::Wz::Xiaodian::OrdersController < ApplicationController
  def index
    @orders = ::EricWeixin::Xiaodian::Order.all
    @orders = @orders.where("openid = ?", params[:openid]).order('order_create_time DESC') unless params[:openid].blank?
    @orders = @orders.paginate(page: params[:page]||1, per_page: 10)
    render :layout => false
  end
end
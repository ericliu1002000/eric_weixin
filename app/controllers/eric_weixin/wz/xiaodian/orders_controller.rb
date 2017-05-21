class EricWeixin::Wz::Xiaodian::OrdersController < ApplicationController
  def index
    @orders = ::EricWeixin::Xiaodian::Order.all
    @orders = @orders.where("openid = ?", params[:openid]).order('order_create_time DESC') unless params[:openid].blank?
    @orders = @orders.paginate(page: params[:page]||1, per_page: 10)
    render :layout => false
  end

  def signin
    order = EricWeixin::Xiaodian::Order.find params[:orderid].to_i
    unless order.openid == params[:openid]
      redirect_to action: :index, openid: params[:openid]
      return
    end
    EricWeixin::Xiaodian::Order.sign_in id: params[:orderid]
    redirect_to action: :index, openid: params[:openid]
  end
end
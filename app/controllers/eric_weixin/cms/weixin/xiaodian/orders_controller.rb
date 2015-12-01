class EricWeixin::Cms::Weixin::Xiaodian::OrdersController < EricWeixin::Cms::BaseController
  def index
    @orders = EricWeixin::Xiaodian::Order.all
  end
end
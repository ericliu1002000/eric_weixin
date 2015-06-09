EricWeixin::Engine.routes.draw do
  get "/weixin/service/:app_id" => "wz/weixin#index"
  post "/weixin/service/:app_id" => "wz/weixin#reply"
  get "/weixin/service1/ddd" => "wz/weixin#aa"
  get "/weixin/snsapi" => "wz/weixin#snsapi_api"
  get "/weixin/snsuserinfo" => "wz/weixin#snsapi_userinfo"
end

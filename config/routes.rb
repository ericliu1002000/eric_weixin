EricWeixin::Engine.routes.draw do
  get "/weixin/service/:app_id" => "wz/weixin#index"
  post "/weixin/service/:app_id" => "wz/weixin#reply"
  get "/weixin/service1/ddd" => "wz/weixin#aa"
  get "/weixin/snsapi" => "wz/weixin#snsapi_api"
  get "/weixin/snsuserinfo" => "wz/weixin#snsapi_userinfo"
  namespace :cms do
    namespace :weixin do
      resources :public_accounts do
        member do
          get :rebuild_weixin_users
          get :export
          post :create_menu
        end
      end

      resources :weixin_users

      resources :article_datas
      resources :news_datas
      resources :users do
        member do
          post :modify_remark
        end
      end
      resources :reply_message_rules

      resources :two_dimension_codes
      resources :url_encodes


      resources :customs_service_records

    end
  end
end

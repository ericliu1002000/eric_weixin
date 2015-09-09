EricWeixin::Engine.routes.draw do
  get "/weixin/service/:app_id" => "wz/weixin#index"
  post "/weixin/service/:app_id" => "wz/weixin#reply"
  get "/weixin/service1/ddd" => "wz/weixin#aa"
  get "/weixin/snsapi" => "wz/weixin#snsapi_api"
  get "/weixin/snsuserinfo" => "wz/weixin#snsapi_userinfo"

  get "/weixin/pay" => "wz/pays#prepay"
  get "/weixin/sendredpack" => "wz/pays#sendredpack"

  namespace :cms do
    namespace :weixin do
      resources :public_accounts do
        member do
          get :rebuild_weixin_users
          get :export
          post :create_menu
        end
      end
      resources :weixin_users do
        member do
          post :modify_remark
        end
      end

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

      resources :media_resources
      resources :media_articles do
        collection do
          get :select_pic
        end
      end

      resources :media_news do
        collection do
          get :query_media_articles
          get :will_send_articles
          post :save_news
          post :preview
          post :send_news_now
          get :query_weixin_users
        end
      end
    end
  end
end

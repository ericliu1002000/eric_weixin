module EricWeixin
  class ApplicationController < ActionController::Base
    def get_ip
      request.env["HTTP_X_FORWARDED_FOR"]
    end
  end
end

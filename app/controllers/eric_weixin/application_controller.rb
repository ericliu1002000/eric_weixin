module EricWeixin
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'pp'
    # helper :all # include all helpers, all the time
    helper_method :current_user, :get_session_content

    #处理控制器中的异常信息。
    def dispose_exception e, error_messages={:unknow_error=>nil, :act=>nil}
      case e
        when BusinessException
          set_notice e.to_s
          return
        when ActiveRecord::RecordInvalid #对于模型中的字段校验，则返回一个hash，分别是字段所对应的错误信息。
          errors = {}
          e.record.errors.each do |k, v|
            k = k.to_s
            errors[k] = v
          end
          set_notice errors
          errors.to_logger
          '.............hash'.to_logger
          return
        when ActiveRecord::RecordNotFound
          set_notice '记录未被找到'
          e.to_s.to_logger
          $@.to_logger
          return
        else
          e.to_s.to_logger
          $@.to_logger
          ExceptionNotifier.notify_exception(e)
          raise e
          set_notice error_messages[:unknow_error]||'发生未知错误'
          return
      end
    end

    def set_notice str
      session[:notice] = str
    end

    def get_notice
      str = session[:notice]
      session[:notice] = nil
      str
    end


    def get_notice_str is_all=true
      if session[:notice].class == String
        str = session[:notice]
        session[:notice] = nil
        str
      end
      if is_all
        return str if not str.blank?
        h = get_notice_hash
        if h.values.length>0
          return h.values[0]
        end
      else
        return str
      end
    end

    def get_notice_hash
      if session[:notice].class == Hash
        str = session[:notice]
        session[:notice] = nil
        str
      else
        Hash.new('')
      end
    end



    def set_session_content
      s = SessionContent.new(value: params.symbolize_keys.delete_if { |key, value| [:utf8, :authenticity_token].include? key }.to_s)
      s.save!
      s.id
    end

    def get_session_content id
      return {} if id.blank?
      begin
        s = SessionContent.where(id: id, is_valid: true).first
        return {} if s.blank?
        s.update_attribute :is_valid, false
        value = eval(s.value)
        value.deep_symbolize_keys
      rescue Exception => e
        {}
      end
    end

    def get_ip
      ip = request.env["HTTP_X_FORWARDED_FOR"]||"127.0.0.1"
      ip = begin ip.split(',')[0] rescue "127.0.0.1" end
    end
  end
end

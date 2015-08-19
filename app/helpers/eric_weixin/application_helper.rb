module EricWeixin
  module ApplicationHelper
    def get_show_value default_value, options
      return options[:v1] unless options[:v1].blank?
      return options[:v2] unless options[:v2].blank?
      return options[:v3] unless options[:v3].blank?
      default_value||''
    end
  end
end

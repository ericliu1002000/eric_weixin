module EricWeixin::Cms::Weixin::PublicAccountsHelper
  def weixin_menu_show_tag json
    puts "****"*300
    puts json.class
    puts "****"*300
    return '<h6>还没有任何菜单哦！</h6>' if json.blank? || json == "null"
    result = '<table border="1" style="word-break:break-all;"><thead><th width="140">button name</th><th width="140">sub_button name</th><th width="60">type</th><th width="150">key</th><th>url</th></thead><tbody>'
    obj = JSON.parse json
    button = obj['button']
    menu_lv1_count = button.count
    0.upto menu_lv1_count-1 do |fi|
      if button[fi]['sub_button'].blank? || button[fi]['sub_button'].count == 0
        result += "<tr><td>#{button[fi]['name']}</td><td></td><td>#{button[fi]['type']}</td><td>#{button[fi]['key']}</td><td>#{button[fi]['url']}</td></tr>"
      else
        sub_button = button[fi]['sub_button']
        menu_lv2_count = sub_button.count
        result += "<tr><td rowspan='#{menu_lv2_count}'>#{button[fi]['name']}</td><td>#{sub_button[0]['name']}</td><td>#{sub_button[0]['type']}</td><td>#{sub_button[0]['key']}</td><td>#{sub_button[0]['url']}</td></tr>"
        if menu_lv2_count >= 2
          1.upto menu_lv2_count-1 do |si|
            result += "<tr><td>#{sub_button[si]['name']}</td><td>#{sub_button[si]['type']}</td><td>#{sub_button[si]['key']}</td><td>#{sub_button[si]['url']}</td></tr>"
          end
        end
      end
    end
    result += '</tbody></table>'
    result
  end
end

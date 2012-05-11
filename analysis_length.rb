require 'rubygems'
require 'common_unity'
$KCODE='u'
class LengthAna
  include CommonUnity
  def initialize
    load_oauth_account
    load_mysql_info
    load_ecommerce
    @dbtable='statuses_all'
  end
  
  def analyse_length
    if @sdate==nil or @edate==nil
      puts "set sdate and edate first !"
      return
    end
     # @account.each{|name,id|
        # _analyse_length(name)
            # }
      account=['亚马逊中国','天猫','京东商城','当当网','杜蕾斯官方微博']
       account=['亚马逊中国']
      account.each{|name|
      _analyse_length(name)
          }
  end
  
  def _analyse_length (uscreen_name)
    my = get_sql_client
    puts "---------------------------------------------------#{uscreen_name}---------------------------------"
    ha = Hash.new
    @sql = "select text,reposts_count,comments_count from #{@dbtable} where uscreen_name='#{uscreen_name}' and created_at >='#{@sdate} 00:00:00' and created_at<='#{@edate} 23:59:59'"
    res=my.query(@sql)
   # puts @sql
    maxlen=0
    t=0
    while row=res.fetch_row
      text=row[0]
      text=text.strip
      re=row[1].to_i
      co=row[2].to_i
      len = text.split(//u).length #获取中文长度
      if maxlen<len
        maxlen=len
      end
#       
      if ha[len]==nil
        ha[len]=[1,re,co]
      else
        ha[len][0]+=1
        ha[len][1]+=re
        ha[len][2]+=co
      end
    end#while

    
    #每个长度分析
    l_a=[]
    s_a=[]
    re_a=[]
    co_a=[]
    
    0.upto(249){|i|
      l_a<<i
    if ha.has_key?(i)
      s_a<<ha[i][0]
      re_a<<ha[i][1]
      co_a<<ha[i][2]
    else
      s_a<<0
      re_a<<0
      co_a<<0
    end
         }
   puts l_a*SEPARATOR
   puts s_a*SEPARATOR
   puts re_a*SEPARATOR
   puts co_a*SEPARATOR
   
        # 区间分析 1-50 ,51-100 ,101-150,151-200,201-250
   s_a=[0,0,0,0,0]
   re_a=[0,0,0,0,0]
   co_a=[0,0,0,0,0]
   0.upto(249){|i|
     if ha.has_key?(i)
       s_a[i/50]+=ha[i][0]
      re_a[i/50]+=ha[i][1]
      co_a[i/50]+=ha[i][2]
     end
         }
   puts s_a*SEPARATOR
   puts re_a*SEPARATOR
   puts co_a*SEPARATOR
   
  end #_analyse_length
end #LengthAna
x=LengthAna.new
x.sdate='2012-1-1'
x.edate='2012-4-28'
x.analyse_length 
require 'rubygems'
require 'weibo'
require 'json'
require 'parsedate'
require 'mysql'
$KCODE='u'

########################################################################################################################
# 0. set date
# 1.get statuses
# 2. get long_link and filter,remain only dp
# 3. get retweet num and comment num
# 4. robot get title
# 5. find out which is unchanged/changed

# w = WeiboAt.new
# w.edate="2012-5-3"
# w.sdate="2012-3-16"
# w.get_share_from_amazon
# w.get_long_url
# w.classify

########################################################################################################################

class WeiboAt
  
  CountOnce=200 #每次调用api获取的微博数目
  SleepZero = 5
  SleepRestart = 60
  SleepOutRate = 1800
  ApiInterval = 0.1
  
  attr_accessor :sdate,:edate
  
  def initialize()
    load_oauth_account
    load_mysql_info
    @sep="|"
  end
  
  def load_oauth_account
    o = YAML.load_file("config/local.yml")['oauth']
    @atoken=[]
    @asecret=[]
    o.each{|item|
     @atoken<<item['oauth_token']
     @asecret<<item['oauth_token_secret']
          }
    @token_num = -1
  end
  
  def load_mysql_info
     o = YAML.load_file("config/local.yml")['mysql']
     @mysql_user = o['user']
     @mysql_passwd = o['password'].to_s
     @mysql_host = o['host']
     @mysql_db = o['db']
  end 
  
  def  get_client
     #@token_num 代表上次使用的token,-1是初始化的值
     if @token_num==@atoken.size
       sleep SleepOutRate
     end
     @token_num=(@token_num+1)%@atoken.size    
     @oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
     @oauth.authorize_from_access(@atoken[@token_num],@asecret[@token_num])
     client  = Weibo::Base.new(@oauth)
     client
  end
  
  def check_date
     if @edate == nil or @sdate == nil
       puts "please set edate and sdate before run this function"
       return false
     else
       return true
    end
  end
  
  #从数据库里面获得@亚马逊中国的微博
  
  def get_share_from_amazon
     f_out = File.open("share_from_amazon_#{@sdate}TO#{@edate}","w")
     my = Mysql.connect(@mysql_host,@mysql_user,@mysql_passwd,@mysql_db)
     sql = "select id,uscreen_name,created_at,text from at_detail where (created_at between '#{@sdate}' and '#{@edate}') and (text like '%刚在@亚马逊中国%'  or text like '%分享自 @亚马逊中国%' or source like  '%亚马逊中国%') order by created_at desc;"
     res = my.query(sql)
     while row = res.fetch_row
       f_out<<row*@sep<<"\n"
     end
     f_out.close
  end
  
  def get_long_url
    f_in =  File.open("share_from_amazon_#{@sdate}TO#{@edate}","r")
    f_out =  File.new("share_from_amazon_#{@sdate}TO#{@edate}_long","a")
    client = get_client
    success = 1
    begin
      while !f_in.eof
        if success == 1
           line = f_in.readline.chomp
           arr = line.split("|")
           text = arr[3]
           text =~/(http:\/\/t.cn\/[0-9|A-Z|a-z]+)/
           url = $1
        end
        item = ""
        if url == nil
          arr<<"none"
        else
          res = client.short_url_expand({:url_short=>url})
          url_long = res[0]['url_long']
          arr<<url_long
        end
        f_out<<arr*@sep<<"\n"
        puts arr*@sep
        f_out.flush
        success = 1
      end
      f_out.close
    rescue =>err
      f_out.flush
      success = 0
      if err.to_s =~/out of rate/
         get_client
         redo
       else
         puts err
         puts line
         next
      end
    end  #begin
  end #get_long_url
  
  def ctr_treatment
    f_in =  File.open("share_from_amazon_#{@sdate}TO#{@edate}_long","r")
    f_out =  File.new("share_from_amazon_#{@sdate}TO#{@edate}_ctrORtreatment","w")
    while !f_in.eof
      line = f_in.readline.chomp
      arr = line.split("|")
      url_long = arr[-1]
      if url_long =~/ref\=cm_sw_r_si_dp/
        arr<<"contrl"
        puts arr*@sep
        f_out<<arr*@sep<<"\n"
      elsif url_long =~/cm_sw_r_sit_dp/
        arr<<"treatment"
        puts arr*@sep
        f_out<<arr*@sep<<"\n"
      end
    end
   end #ctr_treatment
   
   def get_reco
      f_in = File.new("share_from_amazon_#{@sdate}TO#{@edate}_ctrORtreatment","r")
      f_out = File.new("share_from_amazon_#{@sdate}TO#{@edate}_reco","w")

      success = 1
      ids_str = ""
      base = Hash.new
      ids = Array.new
      client = get_client
      while !f_in.eof
        begin
          if success == 1  #更新要查询的ids,否则还是处理上次的ids
            ids = Array.new
            base = Hash.new
            
                                #一次处理20个id
            1.upto(20){
              if !f_in.eof
                line =  f_in.readline.chomp
                arr = line.split("|")
                arr<<0<<0
                id=arr[0]
                base[id] = arr
                ids<<id
              end
                                 }
           end
           ids_str = ids * ","  
           puts "start process #{ids_str}"
           res = client.counts({:ids=>ids_str})
         
           res.each{|item|
                base[item['id'].to_s][-2]=item['rt']
                base[item['id'].to_s][-1]=item['comments']
                                }
          
            ids.each{|id|
                f_out<<base[id]*"|"<<"\n"
                                }
            f_out.flush
            puts "compelet process #{ids_str}"   
            success = 1
            sleep ApiInterval      
        rescue =>err
          f_out.flush
          success = 0
          if err.to_s =~/out of rate/
             get_client
             redo
           else
             puts err
          end
        end #begin 
      end  # while
      f_out.close
   end
end #class 


w = WeiboAt.new
w.edate="2012-5-3"
w.sdate="2012-3-16"
w.get_reco
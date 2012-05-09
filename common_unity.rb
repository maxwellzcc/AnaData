require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'

module CommonUnity
  CountOnce=200 #每次调用api获取的微博数目
  SleepZero = 5
  SleepRestart = 30*60
  SleepNextCycle = 30*60  #get all e-commerce players accounts, then sleep 
  SleepOutRate = 3600
  ApiInterval = 1.5
  SEPARATOR="|"
  
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
  
  def load_mysql_info
     o = YAML.load_file("config/local.yml")['mysql']
     @mysql_user = o['user']
     @mysql_passwd = o['password'].to_s
     @mysql_host = o['host']
     @mysql_db = o['db']
  end 
  
  def load_ecommerce
     @account=Hash.new
     o = YAML.load_file("config/local.yml")['ECommerceAccount']
     o.each{|item|
       @account[item['name']]=item['id'].to_s
            }

  end
  def filter_char item
    item['user']['screen_name'].gsub!(/'/,"")
    item['user']['screen_name'].gsub!(SEPARATOR,"")
    item['source'].gsub!(/'/,"")
    item['source'].gsub!(SEPARATOR,"")
    item['text'].gsub!(/'/,"")
    item['text'].gsub!(SEPARATOR,"")
    if item['retweeted_status']!=nil
      str=item['retweeted_status'].to_s
      str.gsub!(/'/,"")
      str.gsub!(SEPARATOR,"")
      item['retweeted_status'] = str
    end
  end #filter_char
end
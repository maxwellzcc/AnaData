require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'

class AtAmazonCollector 
  CountOnce=200 #每次调用api获取的微博数目
  SleepZero = 5
  SleepRestart = 30*60
  SleepNextCycle = 30*60  #get all e-commerce players accounts, then sleep 
  SleepOutRate = 3600
  ApiInterval = 1.5
  SEPARATOR="|"
  Dbtable='at_amazon_detail'
    
  def initialize
    load_oauth_account
    load_mysql_info
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
  
end
#每个小时获取一次@亚马逊中国的微博

atoken = ['8b4f224910c9b2a42f1bc5895cabe27e']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)
Dbtable = "at_detail"
my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')


log_file = File.open("log_at","w")
#获取当前数据库中最近的微博
res = my.query("select id,created_at from "+Dbtable+" order by created_at desc limit 1;")
row = res.fetch_row
since_id = row[0]
since_created_at = Time.mktime(*ParseDate.parsedate(row[1]))
puts "database newest id is #{since_id}, its time is #{since_created_at.strftime("%Y-%m-%d %H:%M:%S")}"



CountOnce=200 #每次调用api获取的微博数目
SleepZero = 5
SleepRestart = 60
SleepOutRate = 3600
ApiInterval = 3

max_id = ""
max_created_at=""
while true
  begin
    if max_id == ""
      max_created_at=since_created_at
      puts "#{Time.now}---this is a new start!"
      puts "#{Time.now}---get res reomote start"
      res = client.mentions({:count=>CountOnce})
    else
      puts "#{Time.now}---the max_id is #{max_id}, its time is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")}"
      puts "#{Time.now}---get res reomote start"
      res = client.mentions({:count=>CountOnce,:max_id=>max_id})
      res.shift
    end
    puts "#{Time.now}---get res reomote end"
    puts "this time get #{res.size} new statuses"
    
    if res.size == 0
      puts "#{Time.now}---now size is 0,sleep #{SleepZero}"
      log_file<<"#{Time.now}---now size is 0,sleep #{SleepZero}"
      sleep SleepZero
      next
    end
    
    
   
    
    res.each{|item|
        max_id = item['id']
        max_created_at=Time.mktime(*ParseDate.parsedate(item['created_at']))
        
        if (max_created_at <=> since_created_at) <= 0 
          max_id =""
          res = my.query("select id,created_at from "+Dbtable+ " order by created_at desc limit 1;")
          row = res.fetch_row
          since_id = row[0]
          since_created_at = Time.mktime(*ParseDate.parsedate(row[1]))
          puts "database is newest, since_id change to #{since_id}, time is #{since_created_at.strftime("%Y-%m-%d %H:%M:%S")} ,sleep #{SleepRestart}, then restart "
          sleep SleepRestart
          break
        end
        created_at=max_created_at.strftime("%Y-%m-%d %H:%M:%S")
        #remove the char '
        item['user']['screen_name'].gsub!(/(\\)?'/){|c|
                       "\\'"
                      }
        item['source'].gsub!(/(\\)?'/){|c|
                      "\\'"
                      }
        item['text'].gsub!(/(\\)?'/){|c|
                      "\\'"
                    }
                    
        str = item['retweeted_status'].to_s
        str.gsub!(/'/){|c|
                     "\\'"
                    }
        item['retweeted_status']=str


        @sql = "replace into " +Dbtable + " set " +
               "id='#{item['id']}' ,"+
               "uid='#{item['user']['id']}' ,"+
               "uscreen_name='#{item['user']['screen_name']}' ,"+
               "created_at='#{created_at}' ,"+
               "source='#{item['source']}' ,"+
               "reposts_count='#{item['reposts_count']}' ,"+
               "comments_count='#{item['comments_count']}' ,"+
                "annotations='#{item['annotations']}' ,"+
                "text='#{item['text']}' ,"+
                "retweeted_status='#{item['retweeted_status']}' "+
                                     " ;"
       my.query(@sql)
          }
    
    sleep ApiInterval
  rescue =>err
    err_str = err.to_s
    if err_str =~ /out of rate/
      puts "#{Time.now}---out of rate, sleep 3600 "
      log_file<<"#{Time.now}---out of rate, sleep 3600 "
      sleep SleepOutRate
      puts "#{Time.now}---wake up from #{SleepOutRate} sec"
      log_file<< "#{Time.now}---wake up from #{SleepOutRate} sec"
    redo
    else
      puts @sql
      puts "#{Time.now}---------------------------------------------------------------------------------"+err
      log_file<<"#{Time.now}----------------------------------------------------------------------------"+err
      next
    redo
    end
  end
end


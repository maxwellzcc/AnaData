require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'



class StatusesCollector
 
  CountOnce=200 #每次调用api获取的微博数目
  SleepZero = 5
  SleepRestart = 30*60
  SleepNextCycle = 30*60  #get all e-commerce players accounts, then sleep 
  SleepOutRate = 3600
  ApiInterval = 1.5
  SEPARATOR="|"
  Dbtable='statuses_all'
  
  def initialize
    load_oauth_account
    load_mysql_info
    load_ecommerce
    @log_file = File.new("get_statuses_all.log","a")
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
  
  def load_ecommerce
     @account=Hash.new
     o = YAML.load_file("config/local.yml")['ECommerceAccount']
     o.each{|item|
       @account[item['name']]=item['id'].to_s
            }

  end
  
  def get_statuses_all
    @account.each{|uscreenname,uid|
      _get_statues_all(uscreenname,uid)
          }
    puts "now all e-commerce player's statuses are new, sleep #{SleepNextCycle}"
    sleep SleepNextCycle
  end
  

  def _get_statues_all(uscreenname,uid)
    puts "#{Time.now}--begin to get statuses of #{uscreenname}"
    
    #get newest status's created_at
    my = Mysql.connect(@mysql_host,@mysql_user ,@mysql_passwd ,@mysql_db)
    res = my.query("select created_at from "+Dbtable+" where uid= "+uid+" order by created_at desc limit 1;")
    row = res.fetch_row
    if row !=nil and row[0]!=nil
      since_created_at = Time.mktime(*ParseDate.parsedate(row[0]))
    else
      since_created_at = Time.mktime(*ParseDate.parsedate('2012-1-1'))
    end
    
    client = get_client
    max_id = ""
    max_created_at = ""
    
    begin
      while true
        if max_id == ""
          puts "#{Time.now}---#{uscreenname}---this is a new start!"
          puts "#{Time.now}---#{uscreenname}---get res reomote start"
          res = client.user_timeline({:id=>uid,:count=>CountOnce})
        else
          puts "#{Time.now}---#{uscreenname}---the max_id is #{max_id}, its time is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")}"
          puts "#{Time.now}---#{uscreenname}---get res reomote start"
          res = client.user_timeline({:max_id=>max_id,:id=>uid,:count=>CountOnce})
          res.shift
        end
        puts "#{Time.now}---#{uscreenname}---get res reomote end"
        puts "this time get #{res.size} new statuses"
        
        if res.size == 0  #api may return 0, but it does not means there 's no results
          puts "#{Time.now}---#{uscreenname}---now size is 0,sleep #{SleepZero}"
          @log_file<<"#{Time.now}---#{uscreenname}---now size is 0,sleep #{SleepZero}"
          sleep SleepZero
          next
        end
        
        
        res.each{|item|
            max_id = item['id']
            max_created_at=Time.mktime(*ParseDate.parsedate(item['created_at'])) 
            created_at=max_created_at.strftime("%Y-%m-%d %H:%M:%S")
              
            #remove the char '
            filter_char item
        
            @sql = "replace into "+Dbtable+ " set " +
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
        puts "#{Time.now}---#{uscreenname}---max_id is #{max_id} and sleep #{ApiInterval} sec"
        sleep ApiInterval
        
        if (max_created_at <=> since_created_at) <= 0 #if the db is newest
           break
        end  
      end # while
      
     rescue =>err
        err_str = err.to_s
        if err_str =~ /out of rate/
          client = get_client
        else
          puts @sql
          puts "#{Time.now}---#{uscreenname}---"+err
          @log_file<<"#{Time.now}---#{uscreenname}---"+err
        end
        redo
     end #begin
  end #_get_statues_all
  
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
  
end # StatusesCollector

x=StatusesCollector.new
x.get_statuses_all

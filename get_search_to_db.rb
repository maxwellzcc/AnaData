require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'

#每个小时获取一次@亚马逊中国的微博

atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)

my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')
Dbtable="search_detail"

log_file = File.open("log_search","w")
#获取当前数据库中最近的微博
res = my.query("select id,created_at from "+Dbtable+ " order by created_at desc limit 1;")
row = res.fetch_row
since_id = row[0]
since_created_at = Time.mktime(*ParseDate.parsedate(row[1]))
puts "database newest id is #{since_id}, its time is #{since_created_at.strftime("%Y-%m-%d %H:%M:%S")}"



CountOnce=200 #每次调用api获取的微博数目
SleepZero = 5
SleepRestart = 60
SleepOutRate = 1800
ApiInterval = 3

max_id = ""
max_created_at=""

while true
  begin
    if max_id == ""
      max_created_at=since_created_at
      puts "#{Time.now}---this is a new start!"
      puts "#{Time.now}---get res reomote start"
      res = client.status_search("亚马逊",{:count=>CountOnce})
    else
      puts "#{Time.now}---the max_id is #{max_id}, its time is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")}"
      puts "#{Time.now}---get res reomote start"
      res = client.mentions({:count=>CountOnce,:max_id=>max_id})
      res.shift   #上次获取已经处理过了
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
        item['user']['screen_name'].gsub!(/'/){|c|
                       "\\'"
                      }
        item['source'].gsub!(/'/){|c|
                      "\\'"
                      }
        item['text'].gsub!(/'/){|c|
                      "\\'"
                    }
       
        str = item['retweeted_status'].to_s
        str.gsub!(/'/){|c|
                     "\\'"
                    }
        item['retweeted_status']=str
        
        @sql = "replace into " +Dbtable+" set " +
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
    
    puts "#{Time.now}---api sleep #{ApiInterval} sec"
    log_file<<"#{Time.now}--- api sleep #{ApiInterval} sec"
    sleep ApiInterval
  rescue =>err
    err_str = err.to_s
    if err_str =~ /out of rate/
      if token_num==4
        token_num =0 
        puts "#{Time.now}---out of rate, sleep 3600  "
        log_file<<"#{Time.now}---out of rate, sleep 3600"
        sleep SleepOutRate
        puts "#{Time.now}---wake up from #{SleepOutRate} sec"
        log_file<< "#{Time.now}---wake up from #{SleepOutRate} sec"
       else
         token_num+=1
         puts "change token #{token_num}"
      end
    redo
    else
      puts "sql is :" + @sql
      puts "#{Time.now}---"+err
      log_file<<"#{Time.now}---"+err
      next
    redo
    end
  end
end


require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'


#每周四运行一次，从status_amz_cn中取出要分析的微博，分析其转发，周五可以看数据
atoken = ['8b4f224910c9b2a42f1bc5895cabe27e']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)


my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')
log_file = File.open("log_repost","a")
DbTable="repost_detail"

#获取当前数据库中最近的微博
res = my.query("select source_id from repost_detail where source_id=3429242094402359;")
row = res.fetch_row
if row != nil
  max_id = row [0]
  res = my.query("select created_at from statuses_amz_cn where id='#{max_id}' ;")
  row = res .fetch_row
  if row == nil 
    puts "error,exit"
    exit
  end
  max_created_at = row [0]
else
  max_created_at = '0'
end

ids = Array.new
res = my.query("select id from statuses_amz_cn where created_at<'#{max_id}'")
while row = res.fetch_row
  ids<<row[0]
end



CountOnce=50 #每次调用api获取的微博数目
SleepZero = 10
SleepOutRate = 1800
ApiInterval = 3
success = 1


while true
  begin
    
    if ids.size == 0
      break
    end
    
    if success == 1
      id = ids.shift
    end
    
    puts "#{Time.now}---now find the repost of #{id}"
    
    max_id = ""
    while true
        if max_id == ""
          res = client.repost_timeline({:id=>id,:count=>CountOnce})
        else
          res = client.repost_timeline({:id=>id,:count=>CountOnce,:max_id=>max_id})
          res.shift
        end
     
        if res.size == 0
          break
        end
        max_id = res[-1]['id']
        res.each{|item|
                           #放入数据库
           created_at=Time.mktime(*ParseDate.parsedate(item['created_at']))
           created_at=created_at.strftime("%Y-%m-%d %H:%M:%S")
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
           item['retweeted_status']=item['retweeted_status'].to_s.gsub!(/(\\)?'/){|c|
                            "\\'"
                            }
          @sql = "replace into " + DbTable + " set " +
               "source_id='#{id}' ," +
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
    end
    success = 1
     puts "#{Time.now}--- the repost of #{id}  end "
  rescue =>err
    err_str = err.to_s
    puts err_str
    if err_str =~ /out of rate/
      puts "#{Time.now}---out of rate, sleep 3600 now the index is #{id} and sleep 1800 sec"
      log_file<<"#{Time.now}---out of rate, sleep 3600 now the index is #{id} and sleep 1800 sec"
      sleep SleepOutRate
      puts "#{Time.now}---wake up from #{SleepOutRate} sec"
      log_file<< "#{Time.now}---wake up from #{SleepOutRate} sec"
      success = 0
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


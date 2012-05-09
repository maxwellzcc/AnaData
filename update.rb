require 'rubygems'
require 'weibo'
require 'json'
require 'mysql'
$KCODE='u'

# 亚马逊中国
atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)

Dbtable="search_detail"
my=Mysql.connect('localhost','cnsm','123456','cnsmdb')
res = my.quote("select id from "+Dbtable+" ;")
ids = Array.new

while row = res.fetch_row
  ids<<row[0]
end

success = 1
while true
  begin
    if success ==1
      id  = ids.shift
    end
    puts "#{Time.now}---now the id is #{id}"
   
    if since_id == ""
      res = client.user_timeline({:id=>1732523361,:count=>CountOnce})
    else
      res = client.user_timeline({:since_id=>since_id,:id=>1732523361,:count=>CountOnce})
    end
    puts "#{Time.now}---get res reomote end"
    log_file<<"#{Time.now}---get res reomote end"
    
    if res.size == 0
      # #连续10次为0，认为就没有数据了
      # size_sleep_count +=1
      # if size_sleep_count == 10
        # puts "#{Time.now}---now the database is the newest! sleep 1h, then grab data again"
        # log_file<<"#{Time.now}---now the database is the newest! sleep 1h, then grab data again"
        # sleep 1800
        # puts "#{Time.now}---1h has past,now try to grab data"
        # log_file<<"#{Time.now}---1h has past,now try to grab data"
      # end
      # puts "#{Time.now}---size is 0,so sleep 10*#{size_sleep_count}"
      # sleep 10*size_sleep_count
      # puts "#{Time.now}---wake up from 10 sec*#{size_sleep_count}"
      puts "#{Time.now}---now size is 0,sleep #{SleepZero}"
      log_file<<"#{Time.now}---now size is 0,sleep #{SleepZero}"
      sleep SleepZero
      next
    end
    
    puts "this time get #{res.size} new statuses"
    log_file<<"this time get #{res.size} new statuses"
    
    res.each{|item|
        created_at=Time.mktime(*ParseDate.parsedate(item['created_at']))
        created_at=created_at.strftime("%Y-%m-%d %H:%M:%S")
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
        since_id = item['id']
        @sql = "replace into "+DbTable+ " set " +
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
    
    
    puts "#{Time.now}---since_id is #{since_id} and sleep #{ApiInterval} sec"
    log_file<<"#{Time.now}---since_id is #{since_id} and sleep #{ApiInterval} sec"
    sleep ApiInterval
  rescue =>err
    err_str = err.to_s
    if err_str =~ /out of rate/
      if token_num == 4
          token_num =0
          puts "#{Time.now}---out of rate, sleep #{SleepOutRate}  "
          log_file<<"#{Time.now}---out of rate, sleep #{SleepOutRate}"
          sleep SleepOutRate
          puts "#{Time.now}---wake up from #{SleepOutRate} sec"
          log_file<< "#{Time.now}---wake up from #{SleepOutRate} sec"
      else
        token_num += 1
      end
      redo
    else
      puts @sql
      puts "#{Time.now}---"+err
      log_file<<"#{Time.now}---"+err
      next
    redo
    end
  end
end



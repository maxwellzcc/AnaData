require 'rubygems'
require 'common_unity'

class AtAmazonCollector 
  
  include CommonUnity
  def initialize
    load_oauth_account
    load_mysql_info
    @dbtable='at_amazon_detail'
    @log_file = File.open("data/get_at_amazon.log","w")
  end
  
  def get_status_at_amazon
    while true
      _get_status_at_amazon
      puts "now the db is newest,sleep #{SleepRestart}"
      sleep SleepRestart
    end
  end
  def _get_status_at_amazon
    my = get_sql_client
    res = my.query("select created_at from "+@dbtable+" order by created_at desc limit 1;")
    row = res.fetch_row
    if row!=nil and row[0]!=nil      
      since_created_at = Time.mktime(*ParseDate.parsedate(row[0]))
    else
      since_created_at = Time.mktime(*ParseDate.parsedate(DefaultStart))
    end
   
    oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
    oauth.authorize_from_access('8b4f224910c9b2a42f1bc5895cabe27e','914b5341253f6c7f8ca98ce31c2aa472')
    client = Weibo::Base.new(oauth)
    
    max_id = ""
    max_created_at = ""
    
    begin
      while true
         if max_id == ""
          puts "#{Time.now}-----this is a new start!"
          puts "#{Time.now}-----get res reomote start"
          res = client.mentions({:count=>CountOnce})
         else
          puts "#{Time.now}------the max_id is #{max_id}, its time is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")}"
          puts "#{Time.now}------get res reomote start"
          res = client.mentions({:count=>CountOnce,:max_id=>max_id})
          res.shift
        end
        puts "#{Time.now}-----get res reomote end"
        puts "this time get #{res.size} new statuses"
        
        if res.size == 0  #api may return 0, but it does not means there 's no results
          puts "#{Time.now}------now size is 0,sleep #{SleepZero}"
          @log_file<<"#{Time.now}------now size is 0,sleep #{SleepZero}"
          sleep SleepZero
          next
        end
       res.each{|item|
          max_id = item['id']
          max_created_at=Time.mktime(*ParseDate.parsedate(item['created_at'])) 
          created_at=max_created_at.strftime("%Y-%m-%d %H:%M:%S")
            
          #remove the char '
          filter_char item
      
          @sql = "replace into "+@dbtable+ " set " +
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
        puts "#{Time.now}-----max_id is #{max_id} ,it created_at is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")} and sleep #{ApiInterval} sec"
        sleep ApiInterval
        
        if (max_created_at <=> since_created_at) <= 0 #if the db is newest
           my.close
           break
        end  
      end #while
    rescue =>err
      err_str = err.to_s
      if err_str =~ /out of rate/
        puts "#{Time.now}----sleep out of rate #{SleepOutRate}"
        sleep SleepOutRate
      else
        puts @sql
        puts "#{Time.now}------"+err
        @log_file<<"#{Time.now}------"+err
      end
      redo
    end #begin
  end #get_status_at_amazon
end #AtAmazonCollector

x = AtAmazonCollector.new
x.get_status_at_amazon


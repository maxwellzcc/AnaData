require 'rubygems'
require 'common_unity'


#search 接口现在有问题了，不能用

class SearchCollector
  include CommonUnity
  def initialize
    load_oauth_account
    load_mysql_info
    load_ecommerce
    @dbtable='search_detail'
    @log_file = File.new("data/get_search.log","a")
  end
  
  def get_search 
    key_word="亚马逊中国"
    while true
     _get_search key_word
     puts "now all e-commerce player's statuses are new, sleep #{SleepRestart}"
     sleep SleepRestart
    end
  end
  
  def _get_search(key_word)
    puts "#{Time.now}--begin to get statuses of #{key_word}"
    
    #get newest status's created_at
    my = get_sql_client
    res = my.query("select created_at from "+@dbtable+" where key_word= '"+key_word+"' order by created_at desc limit 1;")
    row = res.fetch_row
    if row !=nil and row[0]!=nil
      since_created_at = Time.mktime(*ParseDate.parsedate(row[0]))
    else
      since_created_at = Time.mktime(*ParseDate.parsedate(DefaultStart))
    end
    
    client = get_client
    max_id = ""
    max_created_at = ""
    
    begin
      while true
        if max_id == ""
          puts "#{Time.now}---#{key_word}-----this is a new start!"
          puts "#{Time.now}---#{key_word}-----get res reomote start"
          res = client.status_search(key_word,{:count=>CountOnce,:rpp=>100})
        else
          puts "#{Time.now}---#{key_word}-----the max_id is #{max_id}, its time is #{max_created_at.strftime("%Y-%m-%d %H:%M:%S")}"
          puts "#{Time.now}---#{key_word}-----get res reomote start"
          res = client.status_search(key_word,{:count=>CountOnce,:max_id=>max_id,:rpp=>100})
          res.shift
        end
        puts "#{Time.now}------get res reomote end"
        puts "this time get #{res.size} new statuses"
        
        if res.size == 0  #api may return 0, but it does not means there 's no results
          puts "#{Time.now}---#{key_word}-----now size is 0,sleep #{SleepZero}"
          @log_file<<"#{Time.now}---#{key_word}-----now size is 0,sleep #{SleepZero}"
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
                   "retweeted_status='#{item['retweeted_status']}' ,"+
                   "key_word='#{key_word}' "+
                                               " ;"
           my.query(@sql)
                     }      
        puts "#{Time.now}---#{key_word}---max_id is #{max_id} and sleep #{ApiInterval} sec"
        sleep ApiInterval
        
        if (max_created_at <=> since_created_at) <= 0 #if the db is newest
           my.close
           break
        end  
      end # while
      
     rescue =>err
        err_str = err.to_s
        if err_str =~ /out of rate/
          client = get_client
        else
          puts @sql
          puts "#{Time.now}---#{key_word}---"+err
          @log_file<<"#{Time.now}---#{key_word}---"+err
        end
        redo
     end #begin
  end #_get_search
end # SearchCollector

x = SearchCollector.new
x.get_search
require 'rubygems'
require 'common_unity'


class StatusesCollector
  
  include CommonUnity  
  def initialize
    load_oauth_account
    load_mysql_info
    load_ecommerce
    @dbtable='statuses_all'
    @log_file = File.new("data/get_statuses_all.log","a")
  end
  
  def get_statuses_all
    while true
      @account.each{|uscreenname,uid|
      _get_statues_all(uscreenname,uid)
              }
     puts "now all e-commerce player's statuses are new, sleep #{SleepRestart}"
     sleep SleepRestart
    end
  end
  

  def _get_statues_all(uscreenname,uid)
    puts "#{Time.now}--begin to get statuses of #{uscreenname}"
    
    #get newest status's created_at
    my = get_sql_client
    res = my.query("select created_at from "+@dbtable+" where uid= "+uid+" order by created_at desc limit 1;")
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
            if (max_created_at <=> since_created_at) <= 0 #if the db is newest
              break
            end  
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
        puts "#{Time.now}---#{uscreenname}---max_id is #{max_id} and sleep #{ApiInterval} sec"
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
          puts "#{Time.now}---#{uscreenname}---"+err
          @log_file<<"#{Time.now}---#{uscreenname}---"+err
        end
        redo
     end #begin
  end #_get_statues_all
  
end # StatusesCollector

x=StatusesCollector.new
x.get_statuses_all

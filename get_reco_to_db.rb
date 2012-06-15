require 'rubygems'
require 'common_unity'

class RecoCollector
  include CommonUnity
  def initialize
    load_oauth_account
    load_mysql_info
    load_ecommerce
    @dbtable='statuses_all'
    @log_file = File.new("data/get_reco.log","a")
  end
  
  
  # update statuses_all table with repost and comments #
  # this is the interface method which could control which user's status will be update
  def get_reco_all
      @account.each{|uscreen_name|
      _get_reco_all(uscreen_name)
              }
     # puts "now all e-commerce player's statuses are new, sleep #{SleepRestart}"
     # account=['亚马逊中国','天猫','京东商城','当当网','杜蕾斯官方微博']
     # account.each{|name|
        # _get_reco_all(name)
        # puts "complete update the repost and comment # ,date is from #{@sdate} to #{edate} "
            # }
    check_zero_all
  end
  
  def _get_reco_all(uscreen_name)
    puts "#{Time.now}--begin to check reco # of #{uscreen_name}"
    
    #get newest status's created_at
    
    my = get_sql_client
    @sdate = (Time.now-3600*24*14).strftime("%Y-%m-%d ") if @sdate==nil
    @edate = (Time.now-3600*24*7).strftime("%Y-%m-%d ") if @edate==nil
    @sql = "select id from "+@dbtable+" where uscreen_name= '"+uscreen_name+"' and created_at >= '"+@sdate+" 0:0:0' and created_at <= '"+@edate+" 23:59:59' order by created_at desc;"
    puts @sql
    res = my.query(@sql)
    all_ids = Array.new
    while row = res.fetch_row
      all_ids<<row[0]
    end
    
    success = 1
    ids_str = ""
    base = Hash.new
    ids = Array.new
    client = get_client
    while all_ids.size!=0
      begin
        if success == 1  #更新要查询的ids,否则还是处理上次的ids
          ids = Array.new
          base = Hash.new
          
                              #一次处理20个id
          1.upto(20){
              id=all_ids.shift
              break if id==nil
              base[id] = [0,0]
              ids<<id
                               }
        end
       ids_str = ids * ","  
       puts "start process #{ids_str}"
       res = client.counts({:ids=>ids_str})
       
       res.each{|item|
           #insert into db
          @sql = "update  "+@dbtable+ " set " +
             "reposts_count=#{item['rt']} ,"+
             "comments_count=#{item['comments']} "+
             "where id='#{item['id']}'"+
                                    " ;"
         my.query(@sql)
                    }
      puts "compelet process #{ids_str}"   
      success = 1
      sleep ApiInterval      
      rescue =>err
        success = 0
        if err.to_s =~/out of rate/
           get_client
           redo
         else
           puts @sql
           puts err
        end
      end #begin 
    end #while
    
  end #_get_reco_all
  
  def check_zero_all
    1.upto(3){|index|
      puts "----------------------------now is the #{index} check zero--------------------------"
      account=['亚马逊中国','天猫','京东商城','当当网','杜蕾斯官方微博']
      account.each{|name|
      _check_zero_all(name)
          }
    # @account.each_key{|name|
     # _check_zero_all name
          # }
    }
  
  end
  
  def _check_zero_all(uscreen_name)
     puts "#{Time.now}--begin to check reco # of #{uscreen_name}"
    
    #get newest status's created_at
    
    my = get_sql_client
    @sdate = (Time.now-3600*24*14).strftime("%Y-%m-%d ") if @sdate==nil
    @edate = (Time.now-3600*24*7).strftime("%Y-%m-%d ") if @edate==nil
    @sql = "select id from "+@dbtable+" where uscreen_name= '"+uscreen_name+"' and created_at >= '"+@sdate+" 0:0:0' and created_at <= '"+@edate+" 23:59:59' and reposts_count=0 and comments_count=0 order by created_at desc;"
    res = my.query(@sql)
    all_ids = Array.new
    while row = res.fetch_row
      all_ids<<row[0]
    end
    if all_ids.size == 0
      puts "now all the repost and comment # are not zero ,return"
      return 
    else
      puts "now there #{all_ids.size} zero # need check"
    end
    
    success = 1
    ids_str = ""
    base = Hash.new
    ids = Array.new
    client = get_client
    while all_ids.size!=0
      begin
        if success == 1  #更新要查询的ids,否则还是处理上次的ids
          ids = Array.new
          base = Hash.new
          
                              #一次处理20个id
          1.upto(20){
              id=all_ids.shift
              break if id==nil
              base[id] = [0,0]
              ids<<id
                               }
        end
       ids_str = ids * ","  
       puts "start process #{ids_str}"
       res = client.counts({:ids=>ids_str})
       
       res.each{|item|
           #insert into db
          @sql = "update  "+@dbtable+ " set " +
             "reposts_count=#{item['rt']} ,"+
             "comments_count=#{item['comments']} "+
             "where id='#{item['id']}'"+
                                    " ;"
         my.query(@sql)
                    }
      puts "compelet process #{ids_str}"   
      success = 1
      sleep ApiInterval      
      rescue =>err
        success = 0
        if err.to_s =~/out of rate/
           get_client
           redo
         else
           puts @sql
           puts err
        end
      end #begin 
    end #while
  end #_check_zero_all
  
  def get_reco_at
    #get newest status's created_at
    @dbtable='at_amazon_detail'
    my = get_sql_client
    @sdate = (Time.now-3600*24*14).strftime("%Y-%m-%d ") if @sdate==nil
    @edate = (Time.now-3600*24*7).strftime("%Y-%m-%d ") if @edate==nil
    @sql = "select id from "+@dbtable+" where created_at >= '"+@sdate+" 0:0:0' and created_at <= '"+@edate+" 23:59:59' and reposts_count=0 and comments_count=0 and (source like '%亚马逊%'  or text like '%分享自 @亚马逊中国%') order by created_at desc;"
    res = my.query(@sql)
    all_ids = Array.new
    while row = res.fetch_row
      all_ids<<row[0]
    end
    if all_ids.size == 0
      puts "now all the repost and comment # are not zero ,return"
      return 
    else
      puts "now there #{all_ids.size} zero # need check"
    end
    
    success = 1
    ids_str = ""
    base = Hash.new
    ids = Array.new
    client = get_client
    while all_ids.size!=0
      begin
        if success == 1  #更新要查询的ids,否则还是处理上次的ids
          ids = Array.new
          base = Hash.new
          
                              #一次处理20个id
          1.upto(20){
              id=all_ids.shift
              break if id==nil
              base[id] = [0,0]
              ids<<id
                               }
        end
       ids_str = ids * ","  
       puts "start process #{ids_str}"
       res = client.counts({:ids=>ids_str})
       
       res.each{|item|
           #insert into db
          @sql = "update  "+@dbtable+ " set " +
             "reposts_count=#{item['rt']} ,"+
             "comments_count=#{item['comments']} "+
             "where id='#{item['id']}'"+
                                    " ;"
         my.query(@sql)
                    }
      puts "compelet process #{ids_str}"   
      success = 1
      sleep ApiInterval      
      rescue =>err
        success = 0
        if err.to_s =~/out of rate/
           get_client
           redo
         else
           puts @sql
           puts err
        end
      end #begin 
    end #while
  end
end # class

x = RecoCollector.new
# x.sdate='2012-05-1'
# x.edate='2012-06-06'
# 
# 1.upto(5){
  # x.get_reco_at
  # sleep 1800
#   
# }


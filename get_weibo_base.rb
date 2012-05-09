require 'rubygems'
require 'weibo'
require 'json'
require 'parsedate'
$KCODE='u'

########################################################################################################################
#  a.获取多个电商的微博发布情况，包括id和created_at
#  b 执行前，设置sdate,edate,account
#  c 使用方法:
#     如果要分析 2012－3－16 到 2012－5－3的数据可以是:
# t = WeiboBase.new 
# t.sdate=
# t.edate=
# t.get_weibo_base
# t.get_weibo_base_reco
# t.count_week
# t.count_hour
########################################################################################################################

class WeiboBase
  
  CountOnce=200 #每次调用api获取的微博数目
  SleepZero = 5
  SleepRestart = 60
  SleepOutRate = 1800
  ApiInterval = 0.1
  
  attr_accessor :sdate,:edate
  
  def initialize()
    load_oauth_account
    load_under_analysis_users
    @sep="|"
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
  
  def load_under_analysis_users  
    @account=Hash.new
    o = YAML.load_file("config/local.yml")['AnaUsers']
    o.each{|item| 
       @account[item['name']]={'id'=>item['id'],'fans'=>item['fans']}
          }
    #update yaml file
    
    
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
  
  def check_date
     if @edate == nil or @sdate == nil
       puts "please set edate and sdate before run this function"
       return false
     else
       return true
    end
  end
  
  #获取待分析帐号的微博，id,creadted_at
  def get_weibo_base
    exit if check_date==false
    @account.each_key{|name|      
      _get_weibo_base name
          }
    
  end
  
  def _get_weibo_base (currentU)
     puts "now the currentU is #{currentU}"
     f_out = File.new("data/#{@sdate}TO#{@edate}_#{currentU}","w")
     log = File.new("log_weibo_base","w")
     since=Time.mktime(*ParseDate.parsedate(@sdate))
     max=Time.mktime(*ParseDate.parsedate(@edate))+3600*24
     max_id = ""
     client = get_client
     
     while true
       begin
         puts "#{Time.now}---start:max_id is #{max_id}"
         log << "#{Time.now}---start:max_id is #{max_id}"
         if max_id ==""
           res = client.user_timeline({:id=>@account[currentU]['id'],:count=>CountOnce})
         else
           res = client.user_timeline({:id=>@account[currentU]['id'],:max_id=>max_id,:count=>CountOnce})
           res.shift
         end
           
         if res.size == 0
            puts "size is 0 sleep #{SleepZero},the max_id is #{max_id}"
            sleep SleepZero
            redo
         end
    
         res.each{|item|    
           cur = Time.mktime(*ParseDate.parsedate(item['created_at']))
           if cur >=since and cur <max
             f_out<<item['id']<<"|"<<item['created_at']<<"\n"
           end
           
                        }
         f_out.flush
         
         if Time.mktime(*ParseDate.parsedate(res[-1]['created_at'])) < since
            puts "complete!"
            break
         end
         puts "#{Time.now}---complete:max_id is #{max_id}"
         log << "#{Time.now}--- complete:max_id is #{max_id}"
         max_id = res[-1]['id']
          
      rescue  => err
        f_out.flush
        if err.to_s =~/out of rate/
          client = get_client 
         redo
        else
          puts err
        end
      end  #begin
    end #while
    f_out.close
  end #_get_weibo_base
   
   
   #获取微博的转发评论数目
   def get_weibo_base_reco 
     exit if check_date==false
     @account.each_key{|name|      
      _get_weibo_base_reco name
          }
   end #get_weibo_base_reco
   
   def _get_weibo_base_reco  (currentU)
      puts "currentU is #{currentU}"
      f_in = File.new("data/#{@sdate}TO#{@edate}_#{currentU}","r")
      f_out = File.new("data/#{@sdate}TO#{@edate}_#{currentU}_reco","w")
      log = File.new("log_reco","w")
      success = 1
      ids_str = ""
      base = Hash.new
      ids = Array.new
      client = get_client
      while !f_in.eof
        begin
          if success == 1  #更新要查询的ids,否则还是处理上次的ids
            ids = Array.new
            base = Hash.new
            
                                #一次处理20个id
            1.upto(20){
              if !f_in.eof
                line =  f_in.readline.chomp
                arr = line.split("|")
                arr<<0<<0
                id=arr[0]
                base[id] = arr
                ids<<id
              end
                                 }
           end
           ids_str = ids * ","  
           puts "start process #{ids_str}"
           res = client.counts({:ids=>ids_str})
         
           res.each{|item|
                base[item['id'].to_s][-2]=item['rt']
                base[item['id'].to_s][-1]=item['comments']
                                }
          
            ids.each{|id|
                f_out<<base[id]*"|"<<"\n"
                                }
            f_out.flush
            puts "compelet process #{ids_str}"   
            success = 1
            sleep ApiInterval      
        rescue =>err
          f_out.flush
          success = 0
          if err.to_s =~/out of rate/
             get_client
             redo
           else
             puts err
          end
        end #begin 
      end  # while
      f_out.close
   end  #fun 
   
   def count_week
     exit if check_date==false
     @account.each_key{|name|      
      _count_week name 
            }
   end
   def _count_week currentU
      ha = Hash.new
      f_in = File.new("data/#{@sdate}TO#{@edate}_#{currentU}_reco","r")
      f_out = File.new("data/#{@sdate}TO#{@edate}_week","a")
      puts "---------------------------------------#{currentU} start-------------------------------------------"<<"\n"
      f_out<<"---------------------------------------#{currentU} start-------------------------------------------"<<"\n"
      #f_out<<"星期"<<@sep<<"微博数-#{currentU}"<<@sep<<"转发数-#{currentU}"<<@sep<<"评论数-#{currentU}"<<@sep<<"转发数/微博数-#{currentU}"<<@sep<<"评论数/微博数-#{currentU}"<<@sep<<"#{currentU}"<<"\n"

      while !f_in.eof
        line = f_in.readline.chomp
        arr = line.split("|")
        weekday = arr[1].split(" ")[0]
        if ha.has_key?(weekday)
          ha[weekday][0]+=1
          ha[weekday][1]+=arr[-2].to_i
          ha[weekday][2]+=arr[-1].to_i
        else
          ha[weekday]=[]
          ha[weekday]<<1<<arr[-2].to_i<<arr[-1].to_i
        end
      end
      weeks = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
      0.upto(2){|i|
        arr=Array.new
        weeks.each{|w|
          if ha[w]== nil 
            ha[w]=[]
           ha[w]<<0<<0<<0
          end
          arr<<ha[w][i]
                    }
       puts arr*@sep
       f_out<< arr*@sep<<"\n"
                }
      puts "---------------------------------------#{currentU} end -------------------------------------------"<<"\n\n\n"
      f_out<<"---------------------------------------#{currentU} end -------------------------------------------"<<"\n\n\n"
      f_in.close
      f_out.close
   end
  
   def count_hour
     exit if check_date==false
     @account.each_key{|name|      
      _count_hour name 
            }
   end
   
   def _count_hour currentU
      ha = Hash.new
      f_in = File.new("data/#{@sdate}TO#{@edate}_#{currentU}_reco","r")
      f_out = File.new("data/#{@sdate}TO#{@edate}_hour","a")
      f_out<<"---------------------------------------#{currentU} start-------------------------------------------"<<"\n"
     # f_out<<"小时"<<@sep<<"微博数-#{currentU}"<<@sep<<"转发数-#{currentU}"<<@sep<<"评论数-#{currentU}"<<@sep<<"转发数/微博数-#{currentU}"<<@sep<<"评论数/微博数-#{currentU}"<<@sep<<"#{currentU}"<<"\n"
      while !f_in.eof
        line = f_in.readline.chomp
        arr = line.split("|")
        arr[1] =~/(?:\s)(..):/
        hour = $1
        if ha.has_key?(hour)
          ha[hour][0]+=1
          ha[hour][1]+=arr[-1].to_i
          ha[hour][2]+=arr[-1].to_i
        else
          ha[hour]=[]
          ha[hour]<<1<<arr[-2].to_i<<arr[-1].to_i
        end
      end
      hours =["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"]
      0.upto(2){|i|
        arr=Array.new
        hours.each{|h|
          if ha[h]== nil 
            ha[h]=[]
           ha[h]<<0<<0<<0
          end
          arr<<ha[h][i]
                    }
       puts arr*@sep
       f_out<< arr*@sep<<"\n"
                }
      f_out<<"---------------------------------------#{currentU} end-------------------------------------------"<<"\n\n"
      f_in.close
      f_out.close
   end
   
   def ana_ave
     exit if check_date==false
     f_out = File.new("data/#{@sdate}TO#{@edate}_ave","a")  
     f_out<<"电商"<<@sep<<"微博数"<<@sep<<"转发数/微博数"<<@sep<<"评论数/微博数"<<@sep<<"转发数/微博数/fans数"<<@sep<<"评论数/微博数/fans数"<<@sep<<"fans数"<<"\n"
     @account.each_key{|name|      
     f_out<< _ana_ave(name) <<"\n"
           }
     f_out.close
   end
   
   def _ana_ave currentU
      ha = Hash.new
      f_in = File.new("data/#{@sdate}TO#{@edate}_#{currentU}_reco","r")
      weibo_c,repost_c,comment_c,fans=0.0,0.0,0.0,@account[currentU]['fans']
      while !f_in.eof
        line = f_in.readline.chomp
        arr = line.split("|")
        weibo_c+=1
        repost_c+=arr[-2].to_i
        comment_c+=arr[-1].to_i
      end
      f_in.close
      str = "#{currentU}"+@sep+"#{weibo_c}"+@sep+"#{format("%.1f",repost_c/weibo_c)}"+@sep+"#{format("%.1f",comment_c/weibo_c)}"+@sep+"#{format("%.1f",repost_c/weibo_c/fans)}"+@sep+"#{format("%.1f",comment_c/weibo_c)}"+@sep+fans.to_s+"w"
      str
   end
end #class 


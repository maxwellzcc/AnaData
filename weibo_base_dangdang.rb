require 'rubygems'
require 'weibo'
require 'json'
require 'parsedate'
$KCODE='u'




# AMZ=1732523361
# TMALL = 1768198384
# JINGDONG = 1717871843
# DANGDANG = 1647263235

id=Hash.new
id['amz']=1732523361
id['tmail']=1768198384
id['jingdong']=1717871843
id['dangdang']=1647263235
id['durex']=1942473263

CountOnce=200 #每次调用api获取的微博数目
SleepZero = 5
SleepRestart = 60
SleepOutRate = 1800
ApiInterval = 3


atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client  = Weibo::Base.new(oauth)






sdate="2012-2-1"
edate="2012-4-21"
curentU="durex"   #amz,tmail,jingdong,dangdang,durex


f_out = File.new("#{sdate}TO#{edate}_#{curentU}","w")
log = File.new("log_#{curentU}","w")

since=Time.mktime(*ParseDate.parsedate(sdate))
max=Time.mktime(*ParseDate.parsedate(edate))
max_id = ""

while true
  begin
     puts "start:max_id is #{max_id}"
     log << "start:max_id is #{max_id}"
     if max_id ==""
       res = client.user_timeline({:id=>id[curentU],:count=>CountOnce})
     else
       res = client.user_timeline({:id=>id[curentU],:max_id=>max_id,:count=>CountOnce})
       res.shift
     end
       
     if res.size == 0
        puts "size is 0 sleep #{SleepZero},the max_id is #{max_id}"
        sleep SleepZero
        redo
     end

     res.each{|item|    
       cur = Time.mktime(*ParseDate.parsedate(item['created_at']))
       if cur >=since and cur <=max
         f_out<<item['id']<<"|"<<item['created_at']<<"\n"
       end
       
               }
      f_out.flush
      if Time.mktime(*ParseDate.parsedate(res[-1]['created_at'])) < since
        puts "complete!"
        break
      end
      puts "complete:max_id is #{max_id}"
      log << "complete:max_id is #{max_id}"
      max_id = res[-1]['id']
      
  rescue  => err
    f_out.flush
    str_err = err.to_s
    if str_err =~/out of rate/
      if token_num == 4
        token_num = 0
        puts "out of rate when process #{max_id}"
        log.flush
        puts Time.now
        sleep SleepOutRate
      else
        token_num = token_num + 1
        puts "chage to token #{token_num}"
        oauth.authorize_from_access(atoken[token_num],asecret[token_num])
        client = Weibo::Base.new(oauth)
      end
     redo
    else
      puts str_err
    end
  end
 
end
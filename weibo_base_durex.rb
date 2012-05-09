require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

 # 亚马逊中国
@atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
@asecret = '914b5341253f6c7f8ca98ce31c2aa472'

# test
# atoken = '2acf67ba66e3f49a1a55f83f9aa4048b'
# asecret = '964f430d9900ba38bee294c312d8f1c8'

#woodpeng
# atoken = 'fd2de3188d275c3838b83bae08cad246'
# asecret = '51d227eab665eda707f00555bb4534ff'
# 1768198384   天猫
# 1717871843  京东商城
# 1647263235  当当网
#2433142415 durex

TMALL = 1768198384
JINGDONG = 1717871843
DANGDANG = 1647263235
DUREX = 1942473263
atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client  = Weibo::Base.new(oauth)


f_out = File.new("durex_base","a")
log = File.new("log_durex","a")
max_id = ""
exp = Regexp.new('http://[A-Za-z0-9\.\/]+')


while true
  begin
     puts "start:max_id is #{max_id}"
     log << "start:max_id is #{max_id}"
     if max_id ==""
       res = client.user_timeline({:id=>DUREX,:count=>200})
     else
       res = client.user_timeline({:id=>DUREX,:max_id=>max_id,:count=>200})
       res.shift
     end
       
     if res.size == 0
        puts "size is 0 sleep 1800s,the max_id is #{max_id}"
        sleep 60
        redo
     end
  
     res.each{|item|
       temp =[]
       temp<<item['id']<<item['created_at']<<item['source']
       text = item['text']
       md = exp.match(text)
       unless md == nil
        temp<<md[0]
       else
       temp<<"null"
       end
       f_out<<temp.join(",")<<"\n"
               }
      f_out.flush
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
        sleep 120
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
require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

 # 亚马逊中国
# atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
# asecret = '914b5341253f6c7f8ca98ce31c2aa472'



atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)

f_in = File.new("weibo_jiaqi","r")
f_out = File.new("weibo_jiaqi_count","a")

success = 1
ids_str = ""
base = Hash.new
ids = Array.new
while !f_in.eof
  begin
      if success == 1  #更新要查询的ids,否则还是处理上次的ids
        ids = Array.new
        base = Hash.new
                     #一次处理20个id
        index = 0
        while index < 20 && !f_in.eof
           line =  f_in.readline.chomp
           arr = line.split("|")
           arr<<0<<0
           base[arr[0]] = arr
           ids<<arr[0]
          index = index +1
        end
        ids_str = ids * ","        
      end
      

      puts "start process #{ids_str}"
      res = client.counts({:ids=>ids_str})
      index = 0
      while index<res.size
        base[res[index]['id'].to_s][-2]=res[index]['rt']
        base[res[index]['id'].to_s][-1]=res[index]['comments']
        temp =  base[res[index]['id'].to_s] * "|"
        index = index +1
      end
      base.each_value(){ |item|
        f_out<<item.join("|")
        f_out<<"\n"
               }
      f_out.flush
      puts "compelet process #{ids_str}"   
      success = 1
      sleep 1 
  rescue => err
     f_out.flush
     str_err = err.to_s
     if str_err =~/out of rate/
      if token_num ==4
         token_num = 0
         puts "out of rate when process #{ids_str}"
         puts Time.now
         sleep 120
      else
         token_num = token_num + 1
         puts "chage to token #{token_num}"
         oauth.authorize_from_access(atoken[token_num],asecret[token_num])
         client = Weibo::Base.new(oauth)
      end
      success = 0
      redo
    else
      puts str_err
    end
  end
end
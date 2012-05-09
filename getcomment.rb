require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

 # 亚马逊中国
# atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
# asecret = '914b5341253f6c7f8ca98ce31c2aa472'

# test
# atoken = '2acf67ba66e3f49a1a55f83f9aa4048b'
# asecret = '964f430d9900ba38bee294c312d8f1c8'

#woodpeng
# atoken = 'fd2de3188d275c3838b83bae08cad246'
# asecret = '51d227eab665eda707f00555bb4534ff'

atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)

weibo_id_f = File.new("amazon_weibo_ids_inuse","r")
comments_f = File.new("comments","a")
log_f = File.new("log","w")
line = ""
flag = 1

while !weibo_id_f.eof
  begin
    #如果前一个id真的处理成功，才读取下一个id,否则仍然处理上一个id
    if flag == 1
      line = weibo_id_f.readline 
    end
    source_id = line.split(",")[0]
    log_f<<"start process "<<source_id.to_s<<" \n"
    puts "start process "+source_id.to_s+" \n"
    res = client.comments({:id=>source_id,:count=>100})
    res.each(){ |temp|
      comments_f<<source_id<<","<<temp['id']<<","<<temp['user']['id']<<","<<temp['created_at']<<"\n"
          }
    comments_f.flush

    flag = res.size
    page = 2
    while flag == 100
      max_id = res[res.size-1]['id']
      res = client.comments({:id=>source_id,:count=>100,:page=>page})
      0.upto(res.size-1){|i|
        comments_f<<source_id<<","<<res[i]['id']<<","<<res[i]['user']['id']<<","<<res[i]['created_at']<<"\n"
              }
      page = page +1 
      flag = res.size
    end
    comments_f.flush
    log_f<<"complete process "<<source_id.to_s<<" \n"
    puts "complete process "+source_id.to_s+" \n"
    flag = 1
    sleep 1
  rescue =>err
    comments_f.flush
    str_err = err.to_s
    if str_err =~/out of rate/
      if token_num ==4
         token_num = 0
         puts "out of rate when process #{source_id}"
         log_f.flush
         puts Time.now
         sleep 120
      else
         token_num = token_num + 1
         puts "chage to token #{token_num}"
         oauth.authorize_from_access(atoken[token_num],asecret[token_num])
         client = Weibo::Base.new(oauth)
      end
      flag = 0
      redo
    else
      puts str_err
    end
  end
end

require 'rubygems'
require 'weibo'

# 亚马逊中国
atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
asecret = '914b5341253f6c7f8ca98ce31c2aa472'

# test
# atoken = '2acf67ba66e3f49a1a55f83f9aa4048b'
# asecret = '964f430d9900ba38bee294c312d8f1c8'
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken,asecret)
client = Weibo::Base.new(oauth)

repost_base_f = File.new("repost_base","a")
weibo_id_f = File.new("amazon_weibo_ids_inuse","r")
log_f = File.new("repost_log","a")

while !weibo_id_f.eof
  begin
    source_id = weibo_id_f.readline.split(",")[0]
    log_f<<"start process "<<source_id.to_s<<" \n"
    puts "start process"+source_id.to_s+" \n"
    res = client.repost_timeline({:id=>source_id,:count=>200})
    res.each(){ |temp|
      repost_base_f<<source_id<<","<<temp['id']<<","<<temp['user']['id']<<temp['created_at']<<"\n"
    }
    repost_base_f.flush

    flag = res.size
    while flag >1
      max_id = res[res.size-1]['id']
      res = client.repost_timeline({:id=>source_id,:count=>200,:max_id=>max_id})
      #这里要从1开始，因为max_id在下一次调用的时候，也会返回
      1.upto(res.size-1){|i|
        repost_base_f<<source_id<<","<<res[i]['id']<<","<<res[i]['user']['id']<<res[i]['created_at']<<"\n"
      }
      flag = res.size
    end
    log_f<<"complete process "<<source_id.to_s<<" \n"
    puts "complete process"+source_id.to_s+" \n"
    repost_base_f.flush
  rescue =>err
    repost_base_f.flush
    str_err = err.to_s
    if str_err =~/out of rate/
      puts "out of rate when process #{source_id}"
      log_f.flush
      puts Time.now
      sleep 3600
    else
      puts str_err
    end
  end
end

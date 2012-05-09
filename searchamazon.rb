require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

# 亚马逊中国
atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
asecret = '914b5341253f6c7f8ca98ce31c2aa472'

oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken,asecret)
client = Weibo::Base.new(oauth)


max_id = "3412773356976357"
f_out = File.new("search_amazon","a")

index = 0
page = 1
while true
  begin
    if max_id == ""
      res = client.status_search("亚马逊",{:page=>page,:count=>100})
    else
      res = client.mentions({:max_id=>max_id,:page=>page,:count=>100})
    #去掉第一个,这个已经在上次处理了
      res.shift
    end

    if res.size == 0
      sleep 1800
      next
    end

    index += res.size
    puts "now the total is #{index}"
     res.each{|item|
       f_out<<item['id']<<","<<item['user']['id']<<","<<item['source']<<","<<item['text']<<"\n"
       
     }
     f_out.flush
   
    max_id = res[-1]['id']
    page = page + 1
    puts "max_id is #{max_id}"
    sleep 3
  rescue =>err
    err_str = err.to_s
    if err_str =~ /out of rate/
      puts 'out of rate, sleep 3600 now the index is #{index}'
      sleep 60
    redo
    else
      puts err
    redo
    end
  end
end


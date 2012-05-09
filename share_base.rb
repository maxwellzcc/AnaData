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

exp = Regexp.new('http:\/\/[\w\.\/]+')
max_id = ""
f_out = File.new("share_base","a")

index = 0
while true
  begin
    if max_id == ""
      res = client.mentions({:count=>100})
    else
      res = client.mentions({:count=>100,:max_id=>max_id})
    #去掉第一个,这个已经在上次处理了
    res.shift
    end

    if res.size == 0
    break
    end

    index += res.size
    puts "now the total is #{index}"
    res.each{|item|
      temp = []
      source = item['source']
      if source =~ /亚马逊中国/
        temp<<item['id']<<item['mid']<<item['user']['id']<<item['created_at']<<item['source']
        text = item['text']
        md = exp.match(text)
        unless md == nil
        temp<<md[0]
        else
          temp<<"null"
        end
        line = temp.join(",")
        puts line
        f_out<<line<<"\n"
      f_out.flush
      end
    }
    max_id = res[-1]['id']
    puts "max_id is #{max_id}"
    sleep 1
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


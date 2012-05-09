require 'rubygems'
require 'weibo'
require 'json'
require 'mysql'
require 'yaml'
$KCODE='u'

# 亚马逊中国
atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)
name=URI.escape('当当网电器频道')

# item = client.user_show({:screen_name=>name})
# puts item['id']
# puts item['name']
# puts item['followers_count']
# puts item['created_at']

str=URI.escape("url_short=http://t.cn/zOXeSPv&url_short=http://t.cn/zOXr89Q")
item = client.short_url_expand({:url_short=>str})   
puts item

puts 
#res = client.status(3415822645073229)

# res = client.user(1804086277)
# puts res.class
# 
# puts res.to_s
# Hashie::Mash
# puts 
# exit
# puts 1
# exit



# puts Time.now
# puts nil.to_s

# my = Mysql.new
# my.connect('','','',)
# res = client.status(3427843038206885)
# 
# puts
# 
# #res = client.user_search('亚马逊',{:page=>1})
# # str = URI.escape("亚马逊中国")
# # res = client.status_search("亚马逊中国",{:page=>1,:max_id=>3429673470061174})
# # #res = client.user_show({:screen_name=>'亚马逊中国'})
# # puts 1111111111111111
# # puts res
# # puts res.size
# 
# puts "thsis sjflsjf"
# success = 1
# f_in = File.open("search_amazon_1000","r")
# f_out = File.new("search_amazon_1000_2","a")
# while !f_in.eof
  # begin 
    # if success == 1
      # line = f_in.readline.chomp
       # arr = line.split(",")
       # id = arr[0]
    # end
    # puts "start #{id}"
    # res = client.status(id)
    # if  res ['retweeted_status'] != nil
      # user=res ['retweeted_status']['user']['id']
    # else
      # user = res['user']['id']
    # end
    # f_out << id<<","<<user<<"\n"
    # f_out.flush
    # puts "end #{id}"
    # sleep 0.5
    # success = 1
  # rescue => err
     # f_out.flush
     # str_err = err.to_s
     # success = 0
    # if str_err =~/out of rate/
      # if token_num ==4
         # token_num = 0
         # puts "out of rate when process #{id}"
         # puts Time.now
         # sleep 120
      # else
         # token_num = token_num + 1
         # puts "chage to token #{token_num}"
         # oauth.authorize_from_access(atoken[token_num],asecret[token_num])
         # client = Weibo::Base.new(oauth)
      # end
    # elsif str_err =~/target weibo does not exist!/
      # success = 1
       # text = "\"target weibo does not exist!\""
       # f_out << id<<","<<text<<"\n"
       # f_out.flush
       # puts "end #{id}"
    # else
      # puts str_err
    # end
  # end
# end
# f_out.close


# str = '<a href="http://appserver.lenovo.com.cn/Lenovo_Series_List.aspx?CategoryCode=A21B01" rel="nofollow">sd<'
# str =~/<a.*?>(.*)/
# if $1==nil or $1==""
  # source="未知"
# else 
  # source=$1
  # # source.gsub!(/<\/a>/,"")
  # source = $1 if source =~/(.*)</
# end
#   
# puts source
# a=Hash.new
# a['x'][0]="0"
# a['x'][0]
# puts a['']




# open('text.cfg') { |f| puts f.read }
# 
# open('text.cfg') { |f| YAML.load(f) }

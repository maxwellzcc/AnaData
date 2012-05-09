require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

# 亚马逊中国
atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
asecret = '914b5341253f6c7f8ca98ce31c2aa472'
amz = '1732523361';
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken,asecret)
client = Weibo::Base.new(oauth)
res = client.status(3432894456434601)
puts res
puts 1

#res = client.user_search('亚马逊',{:page=>1})
# id = 3429675181236025
# res = client.status(id)
# puts res
# f = File.new('serach_amazon','r')
# o = File.new('search_amazon_1','a')
# while ! f.eof
  # line = f.readline.chomp
  # arr = line.split(",")
  # unless arr[1] == "1732523361" 
    # o<<line<<"\n"
  # end
#    
# end
# res = client.status(3429672278939822)
# puts res
# f = File.new("search_amazon","r")
# index = 0
# t = 0
# while !f.eof
  # line = f.readline.chomp
  # arr = line.split(",")
  # text = arr[3]
  # user = arr[1]
  # if text =~ /分享自 @亚马逊中国/
    # index = index +1 
  # end
#   
  # if user =="1732523361"
    # t = t +1 
  # end
# end
index = "中文"
puts index

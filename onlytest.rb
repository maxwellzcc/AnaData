require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'


# def parse_source str
  # str =~/<a.*?>(.*)/
  # if $1==nil or $1==""
    # source="未知"
  # else 
    # source=$1
    # source = $1 if source =~/(.*)</
  # end
  # source  
# end
# 
# my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')
# # 
# amazon_id = "1732523361"
# puts amazon_id.class
# res = my.query("select id,uid,uscreen_name,source,text,retweeted_status from search_detail where id ='3433717974470191';")
# file = File.open("search_case2","w")
# sep = "|"
# while  row = res.fetch_row
#   
  # #亚马逊中国发送的微博忽略
   # if row[1] == amazon_id
     # next  
   # end
   # line=""
#    
   # line<<row[0..2]*sep<<sep
   # # puts "----------------------------------"+row[0]
   # source = parse_source row[3]
# 
   # line<<source<<sep<<"\""<<row[4]<<"\""
   # re = row[5]
   # if re == ""
     # puts line
     # file<<line<<"\n"
     # next
   # end
#    
   # re =~/id=(\d+?)\s\w+?=.*?text="(.*?)"\s\w+?=.*?user=#.*?id=(\d+?)\s\w+?=.*?screen_name="(.*?)"\s\w+?=.*/
   # id = $1
   # text = "\""+$2+"\""
   # uid = $3
   # uscreen_name=$4
   # if uid== amazon_id
     # next 
   # end
   # line<<sep<<id<<sep<<uid<<sep<<uscreen_name<<sep<<"\""<<text<<"\""
   # file<< line<<"\n"
# end

#(since_id,max_id]
# res = client.mentions({:since_id=>since_id,:page=>page,:count=>100})
# #如果连续10次size＝0，那么认为确实没有数据了
# puts res
# res.size
# 
# puts 


# str ='#<Hashie::Mash bmiddle_pic="http://ww2.sinaimg.cn/bmiddle/5fbef8b7gw1drwnrst3fnj.jpg" created_at="Thu Apr 12 10:46:10 +0800 2012" favorited=false geo=nil id=3433940889599849 in_reply_to_screen_name="" in_reply_to_status_id="" in_reply_to_user_id="" mid="3433940889599849" original_pic="http://ww2.sinaimg.cn/large/5fbef8b7gw1drwnrst3fnj.jpg" source="<a href="http://a.weibo.com/proc/productintro.php" rel="nofollow">新浪微博企业版</a>" text="维勒贝克有点像当代的巴尔扎克，气势恢宏，野心勃勃。他不会跟你讲一些小情小调，他要讲的是对世界和人类的思考。他把许多现实中的人包括自己，写进了这部小说，读这本书就像在读今天的法国社会，读者将置身于一个虚实难分的故事中。最后，维勒贝克把自己写死在小说里。专题地址: http://t.cn/zON5MIx" thumbnail_pic="http://ww2.sinaimg.cn/thumbnail/5fbef8b7gw1drwnrst3fnj.jpg" truncated=false user=#<Hashie::Mash allow_all_act_msg=true city="1000" created_at="Tue Sep 22 00:00:00 +0800 2009" description="99读书人的出版团队，热爱阅读、热爱出版，致力于满足大家对文字的欲望。 我的豆瓣ID：http://www.douban.com/people/4128318/" domain="" favourites_count=4 followers_count=16163 following=false friends_count=1189 gender="m" geo_enabled=true id=1606351031 location="上海" name="99读书人" profile_image_url="http://tp4.sinaimg.cn/1606351031/50/1279881923/1" province="31" screen_name="99读书人" statuses_count=3489 url="http://blog.sina.com.cn/99readmarket" verified=true>>'
# puts str
# 
# str =~/id=(\d+?)\s\w+?=.*?text="(.*?)"\s\w+?=.*?user=#.*?id=(\d+?)\s\w+?=.*?screen_name="(.*?)"\s\w+?=.*/
# puts $1
# puts $2
# puts $3
# puts $4

# str = "sdfsdfsdfsd \n sdfsfsdf\n"
# # if str =~/\|/
# # str.gsub!(/\|/,"*")
# # end
# str.gsub!("\n"," ")
# puts str


f_in = File.new('search_20120419'+"_long_amz","r")
f_out = File.new('search_20120419'+"_long_amz_asin","w")
gp=0
dp=0
wishlist=0
b=0
s=0
mn=0
other=0
unknow = 0
while !f_in.eof
  line = f_in.readline.chomp
  arr = line.split("|")
  link = arr[-1]
  puts link
  if link=~ /\/wishlist\//
    link<<"|"<<"心愿单"
  elsif link=~ /docId/
    link<<"|"<<"促销"
  elsif link =~/\/([0-9|A-Z|a-z]{10})[^0-9|A-Z|a-z]?/ or link =~/asin=([0-9|A-Z|a-z]{10})/
     link<<"|"<<$1
   else
link="\n"
  end
        f_out<<link<<"\n"
end

puts "gp is #{gp},dp is #{dp},wishlist is #{wishlist},b is #{b},s is #{s},mn is #{mn},other is #{other}"

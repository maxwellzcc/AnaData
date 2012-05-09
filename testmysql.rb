require 'rubygems'
require "mysql"

$KCODE='u'

# $my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')
# 
# ama_id = 1732523361
# f_in = File.open('weibo_detail','r')
 # while !f_in.eof
  # begin
    # line = f_in.readline.chomp;
    # arr = line.split(',')
    # id,timestr,source,links,reposts_count,comments_count = arr
    # time = Time.new
    # time._dump(timestr)
    # datetime = time.strftime("%Y-%m-%d %H:%M:%S")
    # sql = "insert into statuses_amz_cn values (#{id},#{ama_id},'#{datetime}','#{source}','#{links}',#{reposts_count},#{comments_count},null,null,null,null);"
    # #sql = "insert into statuses_amz_cn values (222,1732523361,'2012-04-09 17:23:57','<a href=\"http://a.weibo.com/proc/productintro.php\" rel=\"nofollow\">新浪微博</a>','http://t.cn/zOIW3Nz',11,11,null,null,null,null);"
    # $my.query(sql)
  # rescue
    # next
  # end
# 
# end
# $my.query ("insert into testcn values ('我是呵呵呵呵阿')")------+----------+------+-----+---------+-------+
# | Field          | Type     | Null | Key | Default | Extra |
# +----------------+----------+------+-----+---------+-------+
# | id             | char(30) | NO   | PRI | NULL    |       | 
# | uid            | char(30) | NO   |     | NULL    |       | 
# | created_at     | datetime | YES  |     | NULL    |       | 
# | source         | char(30) | YES  |     | NULL    |       | 
# | links          | char(50) | YES  |     | NULL    |       | 
# | reposts_count  | int(11)  | YES  |     | NULL    |       | 
# | comments_count | int(11)  | YES  |     | NULL    |       | 
# | annotations    | char(30) | YES  |     | NULL    |       | 
# | text           | text     | YES  |     | NULL    |       | 
# | tag            | char(20) | YES  |     | NULL    |       | 
# | backup         | char(20) | YES  |     | NULL    |       | 
# +----------------+----------+------+-----+---------+-------+
# require 'parsedate'
# 
# t = Time.new()
# t=Time.mktime(*ParseDate.parsedate("Thu Mar 22 18:00:36 +0800 2012"))
# res = ParseDate.parsedate("Thu Mar 22 18:00:36 +0800 2012")
# puts *res
# puts t.strftime("%Y-%m-%d %H:%M:%S")
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
res = client.user(1897237150)
puts res
puts res['name']

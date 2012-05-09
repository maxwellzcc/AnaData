require 'rubygems'
require 'weibo'

#载入user表
class AmazonUser
  def initialize (str)
    arr = str.chomp.split(",")
    @id,@flag,
    @followers_count,@friends_count,@statuses_count,@favourites_count,
    @ama_re,@ama_comment,@ama_share,
    @ama_re_re,@ama_re_comment,
    @ama_share_re,@ama_share_comment,
    @tag,@active_time,
    @other,
    @backup = arr
  end
  attr_accessor  :id,:flag, :followers_count,:friends_count,:statuses_count,:favourites_count,
    :ama_re,:ama_comment,:ama_share,
    :ama_re_re,:ama_re_comment,
    :ama_share_re,:ama_share_comment,
    :tag,:active_time,
    :other,
    :backup

  def to_s
    str=""
    arr = Array.new
    arr<<@id<<@flag\
    <<@followers_count<<@friends_count<<@statuses_count<<@favourites_count\
    <<@ama_re<<@ama_comment<<@ama_share\
    <<@ama_re_re<<@ama_re_comment\
    <<@ama_share_re<<@ama_share_comment\
    <<@tag<<@active_time\
    <<@other<<@backup
    arr * ","
  end
end

$KCODE='u'

# 亚马逊中国
# atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
# asecret = '914b5341253f6c7f8ca98ce31c2aa472'

atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client  = Weibo::Base.new(oauth)

f_in = File.new("amazon_user_320_r_inuse")
f_out = File.new("amazon_user_320_ok","a")
log = File.new("log","w")
success = 1

while !f_in.eof
  begin
    if success == 1
      line = f_in.readline.chomp
    end

    user = AmazonUser.new(line)
    id = user.id
            #6已经查寻
    unless user.flag == "-1"
      success = 1
      puts "start process #{id}----local"
    else
      puts "start process #{id}----remote"
      res = client.user(id)
      user.flag = 1
      user.followers_count = res['followers_count']
      user.friends_count = res['followers_count']
      user.statuses_count = res['statuses_count'] 
      user.favourites_count= res ['favourites_count']
    end
    
    
    f_out<<user.to_s<<"\n"
    f_out.flush
    puts "compelet process #{id}"
    log<<"complete process  #{id}\n"
    success = 1
  rescue => err
    f_out.flush
    str_err = err.to_s
    if str_err =~/out of rate/
      if token_num == 4
        token_num = 0
        puts "out of rate when process #{id}"
        log.flush
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

# #repost_detail更新user表
# f_user = File.new("amazon_user_319","r")
# h_users = Hash.new
# #将user载入内存
# while !f_user.eof
# line = f_user.readline.chomp
# user = AmazonUser.new(line)
# h_users [user.id] = user
# end
#
# f_in = File.new("repost_detail","r")
# f_out = File.new("amazon_user_320_r","w")
# while !f_in.eof
# line = f_in.readline
# arr = line.chomp.split(",")
# unless h_users.has_key?(arr[2])
# user = AmazonUser.new(arr[2].to_s+",-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
# user.ama_re = 1
# user.ama_re_re = arr[4].to_i
# user.ama_re_comment = arr[5].to_i
# else
# user = h_users[arr[2]]
# user.ama_re = user.ama_re.to_i+1
# user.ama_re_re = user.ama_re_re.to_i+arr[4].to_i
# user.ama_re_comment = user.ama_re_comment.to_i+arr[5].to_i
# end
# end
#
# #comments_base更新user表
# f_in.close
# f_in = File.new("comments_base","r")
# while !f_in.eof
# line = f_in.readline
# arr = line.chomp.split(",")
# unless h_users.has_key?(arr[2])
# user = AmazonUser.new(arr[2].to_s+",-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
# user.ama_comment = 1
# else
# user = h_users[arr[2]]
# user.ama_comment = user.ama_comment.to_i+1
# end
# end
#
# h_users.each_value{|item|
# f_out<<item.to_s<<"\n"
# }


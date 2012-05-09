require 'rubygems'
require 'json'
require 'weibo'

# config = YAML.load_file('config/weibo.yml')['development']
# atoken = config['atoken']
# asecret = config['asecret']
 # 亚马逊中国
atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
asecret = '914b5341253f6c7f8ca98ce31c2aa472'

# test
# atoken = '2acf67ba66e3f49a1a55f83f9aa4048b'
# asecret = '964f430d9900ba38bee294c312d8f1c8'

#woodpeng
# atoken = 'fd2de3188d275c3838b83bae08cad246'
# asecret = '51d227eab665eda707f00555bb4534ff'

oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
oauth.authorize_from_access(atoken,asecret)
client = Weibo::Base.new(oauth)

ids_file = File.new("amazon_ids_file","r")
fans_file = File.new("amazon_fans","a")
error_file = File.new("notfind_id","w")

id = ids_file.readline.rstrip
num=0

while !ids_file.eof?
  begin
    num = num+1
    puts 'seq is '+num.to_s+' id is'+id
    if num%10==0
      fans_file.flush 
      puts 'write file'
    end
    res = client.user(id)
    #id,粉丝数目,关注数目,微博数目,收藏数目
    fans_file<<res['id']<<','
    fans_file<<res['followers_count']<<','
    fans_file<<res['friends_count']<<','
    fans_file<<res['statuses_count']<<','
    fans_file<<res['favourites_count']<<','

    #对“亚马逊中国”发表微博的转发数目
    fans_file<<'0'<<','

    #对“亚马逊中国”发表微博的评论数目
    fans_file<<'0'<<','
    
    #对“亚马逊中国”发表微博的分享数目（站外，从亚马逊的detailpage分享到weibo的数目）
    fans_file<<'0'<<','

    #转发“亚马逊中国”发表的微博，引起的转发数目
    fans_file<<'0'<<','

    #转发“亚马逊中国”发表的微博，引起的评论数目
    fans_file<<'0'<<','

    #tag
    fans_file<<'-1'<<','

    #活跃时间
    fans_file<<'-1'<<','

    #其他关注
    fans_file<<'-1'<<','

    #备注
    fans_file<<''<<''
    fans_file<<"\n"
    id = ids_file.readline.rstrip
    
  rescue  => err
    fans_file.flush
    err_str = err.to_s
    if err_str =~ /out of rate/
      puts 'out of rate, sleep 3600 now the id is #{id}' 
      sleep 3600
      redo
    elsif err_str  =~ /User does not exists!/
      puts '#{id} User does not exists!'
      id = ids_file.readline.rstrip
      redo
    else
      puts err_str
    end

  end

end
fans_file.close
error_file.close


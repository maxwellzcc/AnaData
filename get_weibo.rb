require 'rubygems'
require 'weibo'
require 'json'

$KCODE='u'

 # 亚马逊中国
@atoken = '8b4f224910c9b2a42f1bc5895cabe27e'
@asecret = '914b5341253f6c7f8ca98ce31c2aa472'

# test
# atoken = '2acf67ba66e3f49a1a55f83f9aa4048b'
# asecret = '964f430d9900ba38bee294c312d8f1c8'

#woodpeng
# atoken = 'fd2de3188d275c3838b83bae08cad246'
# asecret = '51d227eab665eda707f00555bb4534ff'


oauth = Weibo::OAuth.new(Weibo::Config.api_key,Weibo::Config.api_secret)
oauth.authorize_from_access(@atoken,@asecret)
client = Weibo::Base.new(oauth)

@file_weibo = File.new("weibo_file","a")
@flag = 1
@page = 1
 while @flag != 0
  begin
    puts "page:#{@page}"
    res = client.user_timeline({:count=>200,:page=>@page,:max_id=>6653433999})
    @index = 0
    while @index < res.size
      @file_weibo<<res[@index]['id']<<","<<res[@index]['mid']<<"\n"
      @index = @index +1
    end
    @file_weibo.flush
    @page = @page+1
    @flag = res.size
    puts "size is #{@flag}"
  rescue =>err
    err_str = err.to_s
    if err_str =~ /out of rate/
      puts 'out of rate, sleep 3600 now the id is #{id}'
      sleep 3600
      redo
    else
      puts err
      redo
    end
  end
end

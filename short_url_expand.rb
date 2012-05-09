require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'


atoken = ['8b4f224910c9b2a42f1bc5895cabe27e','2acf67ba66e3f49a1a55f83f9aa4048b','fd2de3188d275c3838b83bae08cad246','4524495ca45885d5adbc7662a21cc587','3a6b7a22178ba91e4a78e3d99830b857']
asecret = ['914b5341253f6c7f8ca98ce31c2aa472','964f430d9900ba38bee294c312d8f1c8','51d227eab665eda707f00555bb4534ff','cce28e8a8ce613dd469440a78ab188b6','5b2f87403e80f46c634f39b9f7c972db']
token_num = 0
oauth = Weibo::OAuth.new(Weibo::Config::api_key,Weibo::Config::api_secret)
oauth.authorize_from_access(atoken[token_num],asecret[token_num])
client = Weibo::Base.new(oauth)

f_in = File.new('search_20120419',"r")
f_out = File.new('search_20120419'+"_long","a")

while !f_in.eof
  begin
  line = f_in.readline.chomp
  arr = line.split("|")
  text = arr[5]
  x = text.scan(/http:\/\/t\.cn\/[A-Z|a-z|0-9]+\s?/)
  if x[0]!=nil
    x[0].gsub!(/\s/,"")
    str=URI.escape("#{x[0].to_s}")
    res = client.short_url_expand({:url_short=>str})   
     puts arr[0]+str + res[0]['url_long']
  end
  f_out<<line<<"|"<<res[0]['url_long']<<"\n"
  f_out.flush
  sleep 0.01
  rescue =>err
     err_str = err.to_s
     if err_str =~ /out of rate/
      if token_num==4
        token_num =0 
        puts "#{Time.now}---out of rate, sleep 3600  "
        log_file<<"#{Time.now}---out of rate, sleep 3600"
        sleep SleepOutRate
        puts "#{Time.now}---wake up from #{SleepOutRate} sec"
        log_file<< "#{Time.now}---wake up from #{SleepOutRate} sec"
       else
         token_num+=1
         puts "change token #{token_num}"
      end
     redo
    end
  end
end


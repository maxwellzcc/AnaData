# %w(rubygems bundler).each { |dependency| require dependency }
# %w(sinatra haml oauth sass json weibo).each { |dependency| require dependency }
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


oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
oauth.authorize_from_access(atoken,asecret)
client = Weibo::Base.new(oauth)

res = client.follower_ids()
all_ids = curent_ids = res['ids']

next_cursor = res['next_cursor']
while next_cursor != 0
  res = client.follower_ids({:cursor=>next_cursor})
  curent_ids = res['ids']
  all_ids.concat(curent_ids)
  next_cursor = res['next_cursor']
end
amazon_ids_file = File.new("amazon_ids_file","w")
all_ids.each{|id| amazon_ids_file<<id<<"\n"}
amazon_ids_file.close

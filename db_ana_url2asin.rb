require 'rubygems'
require 'weibo'
require 'mysql'
require 'parsedate'

def url2asin (link)
  res = ""
  if link=~ /\/wishlist\//
    res="心愿单"
  elsif link=~ /docId/
    res="促销"
  elsif link =~/http:\/\/www.amazon.(?:cn|com).+?\/([0-9|A-Z|a-z]{10})[^0-9|A-Z|a-z]/
    res=$1
  elsif link =~/\/gp\/product\/([0-9|A-Z|a-z]{10})$/
    res = $1
  elsif link =~/\/dp\/([0-9|A-Z|a-z]{10})/
    res = $1
  elsif link =~/(?:ASIN|asin)=([0-9|A-Z|a-z]{10})/
    res=$1
  else
    res="未知"
  end
  res
end

f_in = File.new('search_20120419'+"_long_amz","r")
f_out = File.new('search_20120419'+"_long_amz_asin","w")

while !f_in.eof
  line = f_in.readline.chomp
  arr = line.split("|")
  link = arr[-1]
  res = url2asin(link)
  f_out<<line<<"|"<<res<<"\n"
end

# # puts "gp is #{gp},dp is #{dp},wishlist is #{wishlist},b is #{b},s is #{s},mn is #{mn},other is #{other}"



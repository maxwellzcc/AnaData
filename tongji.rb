require 'rubygems'
require 'weibo'

#
# # 亚马逊中国

f_in = File.new("jingdong_detail_23","r")
ha_w = Hash.new
ha_h = Hash.new

while !f_in.eof
  line = f_in.readline.chomp
  arr = line.split(",")
  date = arr[1]
  week = date.split(" ")[0]   #星期统计
  hour = /..:..:../.match(date)[0].split(":")[0]  #小时统计
  if ha_w.has_key?(week)
    ha_w[week][0]= (ha_w[week][0].to_i+1).to_s
    ha_w[week][1]=(ha_w[week][1].to_i+arr[4].to_i).to_s
    ha_w[week][2]=(ha_w[week][2].to_i+arr[5].to_i).to_s
    
   
  else
    ha_w[week]=[]
    ha_w[week]<<1<<arr[4]<<arr[5]
  end
   
   if ha_h.has_key?(hour)
      ha_h[hour][0]= (ha_h[hour][0].to_i+1).to_s
      ha_h[hour][1]=(ha_h[hour][1].to_i+arr[4].to_i).to_s
      ha_h[hour][2]=(ha_h[hour][2].to_i+arr[5].to_i).to_s
   else
      ha_h[hour]=[]
      ha_h[hour]<<1<<arr[4]<<arr[5]
   end
end
# 
# ha_w.each_key{|key|
# arr = ha_w[key]
# arr.insert(0,key)
# puts arr.join(",")
# }
w = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

w.each{|item|
  if ha_w.has_key?(item)
    puts item+","+ha_w[item].join(",")
  else
    puts item + ",0,0,0"
  end
  
}
puts "------------------------------------------------------"
h = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"]
h.each{|item|
  if ha_h.has_key?(item)
    puts item+","+ha_h[item].join(",")
  else
    puts item + ",0,0,0"
  end
}

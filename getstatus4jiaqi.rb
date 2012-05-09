require 'rubygems'
require 'mysql'
require 'parsedate'

# my = Mysql.connect('localhost', 'cnsm', '123456','cnsmdb')
# 
# sql = "select id,created_at   from cnsmdb.statuses_amz_cn where created_at <'2012-4-23' and created_at>'2012-4-9'  order by created_at"
# 
# res = my.query(sql)
# 
# f = File.new("weibo_jiaqi","w")
# while row = res.fetch_row  
  # f<<row*"|"<<"\n"
# end
f = File.new("weibo_jiaqi_count","r")
s = Time.mktime(*ParseDate.parsedate("2012-4-9"))
e = Time.mktime(*ParseDate.parsedate("2012-4-23"))
ha = Hash.new

while !f.eof
  arr = f.readline.chomp.split("|")
  timestr = arr[1]
  t = Time.mktime(*ParseDate.parsedate(timestr))
  if t <e and t>=s
       time = t.to_s.split(" ")[0]
     # time = t.to_s.match(/..:..:../)
     # time = time[0].split(":")[0]
    if ha.has_key?(time)
      ha[time][0]= (ha[time][0].to_i+1).to_s
      ha[time][1]=(ha[time][1].to_i+arr[2].to_i).to_s
      ha[time][2]=(ha[time][2].to_i+arr[3].to_i).to_s
    else
      ha[time]=[]
      ha[time]<<1<<arr[2]<<arr[3]
    end
  end
end 
ha.sort.each{|k,value|
  puts "#{k}\t#{value*"\t"}"
}


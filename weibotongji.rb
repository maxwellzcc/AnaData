f_in = File.new("tmall_detail","r")

ha = Hash.new

while !f_in.eof
  line = f_in.readline.chomp
  arr = line.split(",")
  date = arr[1]
 # time = date.split(" ")[0]
  time = date.match(/..:..:../)
  time = time[0].split(":")[0]
  if ha.has_key?(time)
    ha[time][0]= (ha[time][0].to_i+1).to_s
    ha[time][1]=(ha[time][1].to_i+arr[4].to_i).to_s
    ha[time][2]=(ha[time][2].to_i+arr[5].to_i).to_s
  else
    ha[time]=[]
    ha[time]<<1<<arr[4]<<arr[5]
  end
end

ha.each_key{|key|
arr = ha[key]
arr.insert(0,key)
puts arr.join(",")
}

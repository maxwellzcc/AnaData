require 'rubygems'

file_in = File.new("share_ext","r")
file_out = File.new("share_from_amazon","a")
index = 0
while ! file_in.eof
  line = file_in.readline.chomp
  arr = line.split(",")
  source = arr[4]
  if source =~ /亚马逊中国/
    file_out<<line<<"\n"
  end
end
file_out.close


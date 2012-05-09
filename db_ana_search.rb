require 'rubygems'
require 'mysql'

my = Mysql.connect('localhost','cnsm','123456','cnsmdb')
DbTable = "search_detail"
puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}---mysql ---start"
res = my.query("select id,uid,uscreen_name,created_at,source,text,retweeted_status from "+DbTable+"  where uid!='1732523361' ")
puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}---mysql ----end"
puts "all is " + res.num_rows.to_s
#输出总数：

Sep="|"

f_out = File.new('search_'+Time.now.strftime('%Y%m%d'),"w")
f_err = File.new("search_err","w")
wrong =0

def parse_source str
  str =~/<a.*?>(.*)/
  if $1==nil or $1==""
    source="未知"
  else 
    source=$1
    source = $1 if source =~/(.*)</
  end
  source  
end

re_amz = 0
flag = 1
while row = res.fetch_row
  #row[4]是source
   begin
        
        #将多行文本转为一行
    if row[5]!=""
       row[5].gsub!("\n"," ")
    end
         #过滤text中没有link的
    unless row[5] =~/http:\/\//
      next
    end
    
    # g过滤掉亚马逊发起的投票
    if row[5] =~/我参与了@亚马逊中国 发起的投票/
      next
    end
    
    #将文本中的 | 替换为* ，因为excel处理的时候，用 | 作分隔符号
    if row[5] =~/\|/
      row[5].gsub!(/\|/,"*")
    end

    row[4]= parse_source(row[4])
    line =  row[0...-1]*Sep
    # puts line
    #row[-1]是转发微博
    if row[-1]!=""
      re = row[-1]
                  
                  ## 去掉一些特殊字符和换行
      re.gsub!(/<br \/>/,"")
      re.gsub!(/\n/,"")
                #解析user
      re =~/(user=#<Hashie::Mash.+verified=.+?\>)/
              
              #没有user
      user_str=$1
      if user_str==nil
        uid="未知"
        uscreen_name="未知"
      else
        re.gsub!(user_str,"") #去掉user的内容
        user_str =~/id=(.+?)\s.+screen_name="(.+?)"\s/
        uid=$1
        uscreen_name=$2 
        if uid=='1732523361'
          re_amz +=1
          next
        end
      end
      
      
              # 解析微博


      if re =~/annotations=\[#<Hashie::Mash(.*?)name="(.*?)"\stitle=.*?>>\]/   #投票
        flag =1
        text = "投票: "+$2
        re =~/id=(\d+?)\s/
        id=$1
        
        #puts "id :#{id} uid:#{uid} screen_name:#{screen_name}"
      else  #转发微博
        flag =2
        re =~/id=(\d+?)\s.+text="(.*?)"\s/
        id = $1
        text = $2
       # puts "转发"   ‘
       end
       
      if text =~/\|/
        text.gsub!(/\|/,"*")
      end
      if text!=""
        text.gsub!("\n"," ")
      end
      line<<Sep<<id<<Sep<<uid<<Sep<<uscreen_name<<Sep<<text
      # puts line
    end
    f_out<<line<<"\n"
    # puts line
  rescue =>err
    wrong +=1
    f_err<<"---------------------------------------------------------------------------------------"
    f_err<<"repost is #{row[-1]}"<<"\n"
    f_err<<"line is #{line},id is #{id}, uid is #{uid},uscreen_name is #{uscreen_name} , text is #{text}"<<"\n"
    f_err<<"err is " +err<<"\n"
    next
  end
#    
end
puts "re_amz is #{re_amz}"
puts "wrong is #{wrong}" 
f_out.close


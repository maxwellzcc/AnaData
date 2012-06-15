require 'rubygems'
require 'ftools'
require 'common_unity'
require 'nokogiri'
require 'open-uri'


# 1. get 'mention statuses' to db 
# 2. get repost and comments #
# 3. get data from db to txt 
# 4. change short url to long url
# 5. filter, remain only detailpage and tell the group: treatment or control  
# 6. robot to grab info in contrl group from amaz, which used to tag change 
# 7. decide tag changed or not changed
#  the result will be in data/contentOptimizeResult.log
# 1 and 2 can be done in other files , this class provide method for 3 - 6
class ContentOptimize
  include CommonUnity
  attr_accessor :in_file
  
  def initialize
    load_oauth_account
    load_mysql_info
    @tmp_file='data/tmp.log'
    @in_file='data/contentOptimizeResult.log'
    @robot_file='data/contentOptimizeRobot'
  end

#modify later: filter text,remove | from the text
  def get_data_to_txt
    if @edate==nil or @sdate==nil
      puts 'please set @sdate and @edate'
      return
    end
    
    my = get_sql_client
    sql = "select id,created_at,uscreen_name,text,source,reposts_count,comments_count from cnsmdb.at_amazon_detail where created_at>='#{@sdate} 00:00:00' and created_at <= '#{@edate} 23:59:59' and (source like '%亚马逊%'  or text like '%分享自 @亚马逊中国%') and reposts_count!=0 or comments_count!=0 order by created_at ;"
 
    res = my.query(sql)
    f = File.new(@in_file,'w')
    while row=res.fetch_row
      f<<row*"|"
      f<<"\n"
    end
    f.flush
    f.close
  end # get_data_to_txt 
  
  
  
  def short_url2long_url
    f_tmp = File.open(@tmp_file,'w')
    f_in = File.open(@in_file,'r')
    #short url to long url
    success = 1
    client = get_client
    while !f_in.eof
      if success ==1
        line = f_in.readline
      end
      
      line.chomp!
      arr = line.split('|')
      text = arr[3]
      text =~ /(http:\/\/t\.cn\/[A-Z|a-z|0-9]+)\s?/
      short_url = $1 
      next if short_url==nil
      
      # try 3 times to get long_url
      begin
        1.upto(3){
         res = client.short_url_expand({:url_short=>short_url})
         unless res[0]['url_long']==nil
           puts res[0]['url_long']
           arr<<res[0]['url_long']
           f_tmp<<arr*"|"
           f_tmp<<"\n"
           f_tmp.flush
           sleep 0.5
           break
         end  
                      }
        success=1
      
      rescue => err
        puts err
        if err.to_s =~/Service Unavailable/
           success=0
           client = get_client 
           sleep 1
        end
      end # begin
    end #while
    f_tmp.flush
    f_tmp.close
    f_in.close
    
    File.rename(@in_file,@in_file+".bak")
    File.rename(@tmp_file,@in_file)
           #为当前的url结果单独存一份
    File.copy(@in_file,@in_file+"_l")
    
  end
  
  def group
    f_tmp = File.open(@tmp_file,'w')
    f_in = File.open(@in_file,'r')
    while !f_in.eof
      line = f_in.readline
      line.chomp!
      arr = line.split('|')
      text = arr[3]
      url = arr[-1]

      if url =~/ref=cm_sw_r_sit_dp_/
        arr<<'treatment'
      elsif url =~/ref=cm_sw_r_si_dp_/
         arr<<'control'
      elsif text=~/得来全不费工夫/  or text=~/独乐乐不如众乐乐/ or text=~/分享给你/
        arr<<'treatment'
      else
        next
      end   
      f_tmp << arr* "|"
      f_tmp <<"\n"   
    end  #while
    f_tmp.flush
    f_tmp.close
    f_in.close
    
    File.rename(@in_file,@in_file+".bak")
    File.rename(@tmp_file,@in_file)
  end
  
  
  def robot
    f_robot = File.open(@robot_file,'w')
    f_in = File.open(@in_file,'r')
    
    while !f_in.eof
      line = f_in.readline
      line.chomp!
      arr = line.split('|')
      if arr[-1] =~/treatment/
        next
      end
      
      url = arr[-2]
      
      #try 10 times to get info of product in contrl group
      1.upto(10){|i|
      begin
         if i==10
           f_robot<<url<<"|"<<"none"<<"\n"
           f_robot.flush
           break
         end
         puts "try #{i}:#{url}"
         doc = Nokogiri::HTML(open(url).read.strip)
         topic=  doc.at('span#btAsinTitle').text
         f_robot<<url<<"|"<<topic<<"\n"
         f_robot.flush
         puts "success ------try #{i}:#{url}-----#{topic}"
         break
      rescue =>err
         if err.to_s =~/503\sService\sTemporarily\sUnavailable/
           sleep 5
           next
         end
      end    # begin
              }  
    end # while
    f_in.close
    f_robot.flush
    f_robot.close
  end #robot
  
  def tag_change
    f_tmp = File.open(@tmp_file,'w')
    f_in = File.open(@in_file,'r')
  
    #load url=>topic
    f_r = File.open(@robot_file,'r')
    ha_con = Hash.new
    while !f_r.eof
      line = f_r.readline
      line.chomp!
      arr=line.split('|')
      ha_con[arr[0]]=arr[1]
    end
    f_r.close
    
     while !f_in.eof
      line = f_in.readline
      line.chomp!
      arr = line.split('|')
      text = arr[3]
      long_url = arr[-4]
      if text =~/^得来全不费工夫~我在@亚马逊中国 找到了.*独乐乐不如众乐乐！分享给你： http:\/\/t.cn\/[\w]*\s+\（分享自 @亚马逊中国\）$/  
        arr<<'unchange'  # treatment unchange
      elsif hasSameBegin(text,ha_con[long_url]) and text=~/\（分享自 @亚马逊中国\）$/
        arr<<'unchange'  # control unchange
      else
        arr<<'change'
      end
      
      f_tmp<<arr*"|"
      f_tmp<<"\n"
     end #while
    
    f_tmp.flush
    f_tmp.close
    f_in.close
    
    File.rename(@in_file,@in_file+".bak")
    File.rename('tmp',@in_file)
  end # tag_change
  
  
   #this method is used to tell whether two string have same beginner
   # for example, str1=abcde str2=abcvb it will return true
   #it is used to detemine whether the content in contrl has been changed 
   #it suppose that if str1 and str2 have at least 4 char (or 2 chinese)same, the content is unchanged
  def hasSameBegin str1,str2
     puts str2 if str2!=nil
    return false if str1==nil or str2==nil
   
    i=0
    while i<str1.size and i<str2.size and str1[i]==str2[i] 
      i+=1
    end
    if i>=4
      return true
    else
      return false
    end
  end #hasSameBegin
  
  def demo_use
    x.in_file='res_out'
    x.get_data_to_txt
    x.short_url2long_url
    x.group
    x.robot
    x.tag_change
    #the result is in file 'res_out'
  end
  
  
  #just for testing
  def test
    my = get_sql_client
    sql = "select id,created_at,uscreen_name,text,source,reposts_count,comments_count from cnsmdb.at_amazon_detail where created_at>='#{@sdate} 00:00:00' and created_at <= '#{@edate} 23:59:59' and (source like '%亚马逊%'  or text like '%分享自 @亚马逊中国%') and reposts_count!=0 or comments_count!=0 order by created_at ;"
 
    res = my.query(sql)
   
    while row=res.fetch_row
      if row[0]=~/3449638579557362/
        puts row[3]
        puts row[4]
      end

    end
   
  end #test
  
end
x = ContentOptimize.new
#you can see the demo_run to get how to use this.

    
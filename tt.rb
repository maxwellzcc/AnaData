require 'rubygems'



hs = { "a" => 100, "b" => 200 }
puts hs.has_key?("a")   #=> true
puts hs.has_key?("z")   #=> false
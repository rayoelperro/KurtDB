require './querymaker.rb'
require './database.rb'

d = Kurt::DataBase.new("kurttesting",true)
d.select("/main.json",true,"newtable",["name","surname","age"])
b = Kurt::QueryMaker.new(d)
b.exec("SET newtable VALUES name : one surname : four age : 16")
b.exec("SET newtable VALUES name : two surname : five age : 35")
b.exec("SET newtable VALUES name : three surname : six age : 17")
res = b.exec_result("GET newtable WHERE AND age > 15 ; age < 30")
res.rows do |r|
    r.fields do |f,v|
        puts f.to_s + " -> " + v.to_s
    end
    puts "_________________________________________________"
end
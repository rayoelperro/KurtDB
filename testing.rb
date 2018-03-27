require './querymaker.rb'
require './database.rb'

d = Kurt::DataBase.new("kurttesting",true)
d.select("/main.json",true,"newtable",["name","surname","age"])
=begin
d.q_set("rayoelperro",{name:"alberto",surname:"elorza",age:30})
d.q_del("rayoelperro",{AND:[["age",">",18]],OR:[["name","=","alberto"],["surname","=","elorza"]]})
d.q_set("rayoelperro",{name:"pepe",surname:"elorza",age:20})
d.q_set("rayoelperro",{name:"alberto",surname:"cardenas",age:19})
d.q_set("rayoelperro",{name:"pepe",surname:"martinez",age:40})
d.q_set("rayoelperro",{name:"arnaldo",surname:"navarro",age:40})
puts d.q_get("rayoelperro",{AND:[["age",">",18]],OR:[["name","=","alberto"],["surname","=","elorza"]]})
=end
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
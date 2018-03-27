require './queryresult.rb'

module Kurt
    class QueryMaker
        def initialize(db)
            @db = db
        end
        def is_i?(gibben)
            return /\A[-+]?\d+\z/ === gibben
         end
        def getMode(lin)
            all = lin.split(' ')
            mode = all[0]
            database = all[1]
            if all.length < 2 then raise "Not enought argument for a query" end
            req = []
            case mode
            when "GET", "DEL"
                req = ["WHERE"]
            when "SET"
                req = ["VALUES"]
            else
                raise "Unexpected mode: " + mode
            end
            return [mode,database,lin[lin.split(database)[0].length+database.length,lin.length]]
        end
        def evalPart(there,tno,actual,founds)
            if ["WHERE","AND","OR","VALUES"].include? actual
                if actual == "WHERE"
                    if founds["WHERE"] == true || founds["AND"] == true || founds["OR"] == true || founds["VALUES"] == true
                        raise "Error with keyword 'WHERE'"                                
                    end
                elsif actual == "AND"
                    if founds["WHERE"] == false || founds["AND"] == true || founds["VALUES"] == true
                        raise "Error with keyword 'AND'"                               
                    end
                elsif actual == "OR"
                    if founds["WHERE"] == false || founds["OR"] == true || founds["VALUES"] == true
                        raise "Error with keyword 'OR'"                                
                    end
                elsif actual == "VALUES"
                    if founds["WHERE"] == true || founds["AND"] == true || founds["OR"] == true || founds["VALUES"] == true
                        raise "Error with keyword 'VALUES'"                                
                    end
                end
                founds[actual] = true
                tno = actual
            elsif tno.length > 0
                unless tno == "WHERE"
                    if tno == "AND" || tno == "OR"
                        if is_i?(actual)
                            there["WHERE"][tno].push(actual.to_i)
                        else
                            there["WHERE"][tno].push(actual)
                        end
                    else
                        if is_i?(actual)
                            there[tno].push(actual.to_i)
                        else
                            there[tno].push(actual)
                        end
                    end
                end
            end
            return [there,tno,actual,founds]
        end
        def getParts(restline)
            there = {"WHERE"=>{"AND"=>[],"OR"=>[]},"VALUES"=>[]}
            tno = ''
            actual = ''
            founds = {"WHERE"=>false,"AND"=>false,"OR"=>false,"VALUES"=>false}
            instr = false
            restline.split('').each_with_index do |e,i|
                if actual.length > 0 && (e == ' ' || i == restline.length-1) && !instr
                    if i == restline.length-1
                        actual += e
                    end
                    there,tno,actual,founds = evalPart(there,tno,actual,founds)
                    actual = ''
                elsif e == "'"
                    instr = !instr
                    unless instr
                        there,tno,actual,founds = evalPart(there,tno,actual,founds)
                        actual = ''
                    end
                elsif instr
                    actual += e
                elsif e != ' '
                    actual += e
                end
                if i == restline.length-1 && actual != ' ' && actual.length > 0
                    there,tno,actual,founds = evalPart(there,tno,actual,founds)
                    actual = ''
                end
            end
            return [there, founds]
        end
        def where_query_parser(there)
            where = {AND:[],OR:[]}
            tw = there["WHERE"]
            big = []
            now = []
            unless tw["AND"].length < 1
                tw["AND"].each do |x|
                    unless x == ";"
                        now.push(x)
                    else
                        big.push(now)
                        now = []
                    end
                end
                if now.length > 0
                    big.push(now)
                    now = []
                end
                where[:AND] = big
                big = []
            else
                where[:AND] = nil
            end
            unless tw["OR"].length < 1
                tw["OR"].each do |x|
                    unless x == ";"
                        now.push(x)
                    else
                        big.push(now)
                        now = []
                    end
                end
                if now.length > 0
                    big.push(now)
                    now = []
                end
                where[:OR] = big
                big = []
            else
                where[:OR] = nil
            end
            return where
        end
        def values_query_parser(there)
            values = {}
            valz = there["VALUES"]
            name = ""
            onm = false
            valz.each do |v|
                if onm
                    values[name] = v
                    onm = false
                elsif v == ":"
                    onm = true
                else
                    name = v
                end
            end
            return values
        end
        def exec(query)
            #get: GET database WHERE AND NIL OR name = 'ok' ; surname = 'maybe'
            #del: DEL database WHERE AND name = 'not' OR NIL
            #set: SET database VALUES name : 'new' surname : 'newnew' age : 20
            mode, database, restline = getMode(query)
            there, founds = getParts(restline)
            if ["DEL","GET"].include? mode
                if founds["VALUES"] == true then raise "Error using values keyword in #{mode}" end
                if founds["WHERE"] == false
                    if mode == "DEL"
                        return @db.q_del(database,nil)
                    else
                        return @db.q_get(database,nil)
                    end
                else
                    if mode == "DEL"
                        return @db.q_del(database,where_query_parser(there))
                    else
                        return @db.q_get(database,where_query_parser(there))
                    end
                end
            elsif "SET" == mode
                if founds["WHERE"] == true then raise "Error using values keyword in #{mode}" end
                if founds["VALUES"] == false then raise "Any value gibben" end
                return @db.q_set(database,values_query_parser(there))
            else
                raise "Unknown mode: #{mode}"
            end
        end
        def exec_result(query)
            result = exec(query)
            if result == true then raise "The query doesn't return any value" end
            return Kurt::QueryResult.new(result)
        end
    end
end
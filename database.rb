require 'rubygems'
require 'json'

module Kurt
    class DataBase
        def initialize(name,create)
            @name = name
            @selected = nil
            @latesloading = nil
            if create
                if File.exists?(name)
                    raise "DB Folder: #{name} already created"
                else
                    Dir.mkdir(name)
                end
            else
                unless File.exists?(name)
                    raise "DB Folder: #{name} doens't exists"
                end
            end
        end
        def select(slc,create,mtbl="main",columns=nil)
            if create
                if File.exists?(@name+slc)
                    raise "DB Folder: #{@name+slc} already created"
                else
                    to = {source:slc,tables:[{name:mtbl,model:columns,rows:[]}]}
                    f = File.open(@name+slc,'w')
                    f.puts(JSON.pretty_generate(to))
                    f.close
                end
            else
                unless File.exists?(@name+slc)
                    raise "DB Folder: #{@name+slc} doens't exists"
                end
            end
            @selected = slc
            @latesloading = JSON.parse(File.read(@name+slc))
            unless @latesloading['source'] == slc
                raise "Error selection #{@latesloading['source']} != #slc"
            end
        end
        def save()
            f = File.open(@name+@selected,'w')
            f.puts(JSON.pretty_generate(@latesloading))
            f.close
        end
        def close()
            self.save
            @selected = nil
            @latesloading = nil
        end
        def all_true(lin,where)
            if lin.nil? then return false end
            if where[:AND] != nil
                for i in (0..where[:AND].length-1) do
                    o = lin[where[:AND][i][0].to_s]
                    if o == nil then raise "Wrong key #{where[:AND][i][0].to_s} for #{lin}" end
                    c = where[:AND][i][1]
                    t = where[:AND][i][2]
                    case c
                    when ">"
                        if o < t.to_f then return false end
                    when "<"
                        if o > t.to_f then return false end
                    when "="
                        if o != t then return false end
                    else
                        raise "Unexpected operator #{c}"
                    end
                end
            end
            if where[:OR] != nil
                for i in (0..where[:OR].length-1) do
                    o = lin[where[:OR][i][0].to_s]
                    if o == nil then raise "Wrong key #{where[:AND][i][0].to_s} for #{lin}" end
                    c = where[:OR][i][1]
                    t = where[:OR][i][2]
                    case c
                    when ">"
                        if o > t.to_f then return true end
                    when "<"
                        if o < t.to_f then return true end
                    when "="
                        if o == t then return true end
                    else
                        raise "Unexpected operator #{c}"
                    end
                end
                return false
            else
                return true
            end
        end
        def q_get(table,where=nil)
            unless @selected == nil
                tr = []
                for i in (0..@latesloading['tables'].length-1) do
                    dtb = @latesloading['tables'][i]
                    if dtb['name'] == table
                        if where == nil
                            dtb['rows'].each do |x|
                                tr.push(x)
                            end
                        else
                            dtb['rows'].each do |x|
                                if(all_true(x,where))
                                    tr.push(x)
                                end
                            end
                        end
                    end
                end
                return tr
            else            
                raise "Any database selected"
            end
        end
        def q_del(table,where=nil)
            unless @selected == nil
                for i in (0..@latesloading['tables'].length-1) do
                    dtb = @latesloading['tables'][i]
                    if dtb['name'] == table
                        if where == nil
                            for i in (0..dtb['rows'].length-1) do
                                dtb['rows'].delete(i)
                            end
                        else
                            for i in (0..dtb['rows'].length-1) do
                                if(all_true(dtb['rows'][i],where))
                                    dtb['rows'].delete_at(i)
                                end
                            end
                        end
                    end
                end
                self.save
                return true
            else            
                raise "Any database selected"
            end
        end
        def q_set(table,values)
            unless @selected == nil
                for i in (0..@latesloading['tables'].length-1) do
                    if @latesloading['tables'][i]['name'] == table
                        unless @latesloading['tables'][i]['model'].nil?
                            values.keys.each do |k|
                                unless @latesloading['tables'][i]['model'].include? k.to_s
                                    raise "Invalid key: #{k.to_s}"
                                end
                            end
                        end
                        @latesloading['tables'][i]['rows'].push(values.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo})
                    end
                end
                self.save
                return true
            else
                raise "Any database selected"
            end
        end
    end
end
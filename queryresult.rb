module Kurt
    class Line
        def initialize(line)
            @lin = line
        end
        def fields
            @lin.each do |f,v|
                yield f, v
            end
        end
    end
    class QueryResult
        def initialize(object)
            @obj = object
            @columns = object[0].keys
            @rows = []
            object.each do |l|
                if l.keys != @columns then raise "You need a regular result to make a query result" end
                @rows.push(l.values)
            end
        end
        def get_columns
            return columns
        end
        def get_columns(index)
            return columns[index]
        end
        def get_rows
            return rows
        end
        def get_rows(index)
            return rows[index]
        end
        def rows
            @obj.each do |r|
                yield Line.new(r)
            end
        end
    end
end
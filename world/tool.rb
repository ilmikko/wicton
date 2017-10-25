class Evented
        def trigger(name)
                if @event.key? name
                        @event[name].dup.each{ |e|
                                begin
                                        e.call;
                                rescue StandardError => e
                                        $console.error("EVENT ERROR: #{e}");
                                end
                        }
                end
        end
        def on(name,bd)
                if @event.key? name
                        @event[name]<<bd;
                else
                        @event[name]=[bd];
                end
        end
        def initialize()
                @event={};
        end
end

class IDd < Evented
        @@id=0;
        def id
                @id
        end
        def initialize()
                super();

                @id=@@id+=1;
        end
end

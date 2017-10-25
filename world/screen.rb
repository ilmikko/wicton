require 'io/console';

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
                        @event[name] << bd;
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

class Screen < Evented
        def width
                @dimensions[1]
        end
        def height
                @dimensions[0]
        end
        def dimensions
                [@dimensions[1],@dimensions[0]] # Swapped from h,w to w,h for convenience
        end

        # --------------------------- CURSOR COMMANDS---------------------------
        def cursorHide
                $stdout.write("\033[?25l");
        end
        def cursorShow
                $stdout.write("\033[?25h");
        end

        # --------------------------- SCREEN COMMANDS---------------------------
        def clear
                $stdout.write("\033c");
                self.cursorHide();
        end
        def resize
                @dimensions=$stdin.winsize;
                self.trigger(:resize);
        end

        # -------------------------- GRAPHICS COMMANDS--------------------------

        def write(str='')
		$stdout.write(str);
        end

        def put(x,y,str)
                h,w=@dimensions;

                if (x>=w||y>=h||y<0)
                        # Starting point out of bounds
                        return;
                end

                # under/overflow prevention
                if (x<0)
                        str=str[-x..-1];
                        x=0;
                end

                if (x+str.length>w)
                        str=str[0..w-x-1];
                end

                x=(x+1).round.to_i;
                y=(y+1).round.to_i;

                $stdout.write("\033[" << y.to_s << ';' << x.to_s << 'H' << str.to_s);
        end

        def initialize()
                super();

                @dimensions=0,0;

                self.clear();
                self.resize();

                # New thread for resizing check
                resizethr = Thread.new{
                        while true
                                # Resize check, every n frames
                                if ($stdin.winsize!=@dimensions)
                                        self.clear();
                                        self.resize();
                                end

                                # Everyone needs some rest
                                Kernel::sleep(1.0/30.0);
                        end
                }
        end
        def close
                self.clear();
                self.cursorShow();
                self.trigger(:close);
        end
end

$screen=Screen.new;

at_exit{
	$screen.close();
}

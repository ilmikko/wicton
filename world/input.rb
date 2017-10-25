require("io/console");

class Input
        def listen(keys)
                keys.each{ |l,k|
                        self.rule(l,k);
                }
        end
        def rule(key,action)
                key=key.to_sym;

                if @rules.key? key
                        rule=@rules[key];

                        if (rule.respond_to? :call)
                                @rules[key]=rule=[rule];
                        end

                        rule.push(action);
                else
                        @rules[key]=[action];
                end
        end
        def initialize

                x = ->{
			if $main
				$main.close('user signal');
			else
				exit;
			end
                };

                @rules={
                        "\u0003":x,
                        'q':x
                };

                STDIN.echo = false;
                STDIN.raw!

                Thread.new{
                        # Keypress check
                        while true
                                char = STDIN.getch;

                                # Escape characters
                                if (char=="\u001b")
                                        char+=STDIN.getch+STDIN.getch;
                                end

                                key=char;

                                begin
                                        key=key.to_sym;
                                        if @rules.key? key
                                                rule=@rules[key];

                                                # Check if rule is iterable
                                                if (rule.respond_to? :each)
                                                        rule.each{ |f|
                                                                f.call();
                                                        }
                                                # Check if it's callable
                                                elsif (rule.respond_to? :call)
                                                        rule.call();
                                                end
                                        end
                                rescue StandardError => e
                                end
                        end
                }
        end

        def close
                STDIN.echo = true;
                STDIN.cooked!
        end
end

$input=Input.new();

at_exit{
	$input.close();
}

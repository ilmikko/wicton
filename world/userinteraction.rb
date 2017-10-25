# A module to help interact with the world by various user inputs.
require("./console.rb");
require("io/console");

class InputConsole
	def menus;@menus;end
	def menus=(v);
		@menus.merge!(v);
	end
	def initialize()
		@path=[];
		@menu=:default;
		@menus={
			default: {
				'x':->{
					exit if $input.confirm?('Are you sure you want to end the simulation?',default: false);
				},
				'h':->{
					$console.info('Can anyone help you?');
				},
				's':->{
					# status screen
					Actor.list.each{|actor|
						$console.info("A: #{actor.name} (#{actor.location},#{actor.status})");
					}
				},
				' ':->{
					# pause / unpause
					$paused=!$paused;
					if $paused
						$console.info("Simulation paused...");
					else
						$console.info("Simulation unpaused...");
					end
				},
				'a':->{
					#Actors
					$console.info('ACTORS');
					$input.choose(Actor.list,->(actor){
						$console.info("ACTORS > #{actor.name}");
						$console.info("Name: #{actor.fullname} (#{actor.name})");
						$console.info("Location, status, frust: #{actor.location}, #{actor.status}, #{actor.frustration}");
						$console.info("Traits: ");
						actor.traits.dict.each{ |trait,value|
							$console.info("#{trait} = #{value}");
						}

						$input.branch({
							'1. Move to':->{
								$console.info("ACTORS > #{actor.name} > MOVE TO");
								$console.info("Available locations:");
								$input.choose($world.places.keys,->(location){
									actor.addTask(:move,location);
								});
							}
						});
					},map:->(i){ i.name; });
				},
				'p':->{
					#Inspect
					$console.info('PLACES');
					self.choose($world.places.values,->(place){
						$console.info("PLACES > #{place.name}");
						$console.info("Population: #{place.actors.size}/#{place.size}");
						$console.info("Connected to: #{place.connections}");
						self.branch({
							'1. Actors':->{
								# List actors
								$console.info("PLACES > #{place.name} > ACTORS");
								actors=place.actors;
								$console.info("Place #{place.name} has #{actors.length} actor(s)");
								actors.each{ |actor|
									$console.info("#{actor.name}");
								}
							}
						});
					},map:->(i){ i.name; });
				},
			}
		};

		# Super menu never changes
		@supermenu={
			"\u0003":->{
				#Ctrl-C
				exit;
			}
		};
		# Sub menu always changes
		@submenu={};
		Thread.new{
			# Keypress check
			while true
				STDOUT.write("\r\n");
				char = STDIN.getch;

				# Escape characters
				if (char=="\u001b")
					$console.debug("Escaped, 2 more");
					char+=STDIN.getch+STDIN.getch;
				end

				$console.debug("Input: [#{char}](#{char.ord})");

				key=char;

				begin
					key=key.to_sym;
					rules={};
					$console.debug("Merging #{@menu}");
					rules.merge!(@menus[@menu]);
					rules.merge!(@submenu);
					rules.merge!(@supermenu);
					if rules.key? key
						$console.debug("Input: #{char} exists in rules");
						rule=rules[key];

						if (rule.respond_to? :call)
							rule.call();
							STDOUT.putc("#{key}");
						else
							$console.error("Cannot parse rule for key #{key}! (#{rule})");
						end
					end
				rescue StandardError => e
					$console.error("INPUT: ERROR #{e}");
				end
			end
		}
	end
	def changeMenu(menu)
		throw "Can't find menu: #{menu}" if !@menus.key? menu;
		@menu=menu;
		@submenu={};
	end
	def branch(obj)
		options={};
		obj.each{ |k,v|
			options[k[0].downcase.to_sym]=v;
			$console.info("#{k}");
		}
		@submenu=options;
		$console.info("q. Cancel");
		@submenu.merge!({ 'q':->{@submenu={};} });
	end
	def choose(arr,f,map: ->(i){i.to_s})
		procs=arr.map{|i| ->{ @submenu={};f.(i); }}
		options={};
		for i in 0...arr.length
			options[(i+1).to_s.to_sym]=procs[i];
			$console.info("#{i+1}. #{map.(arr[i])}");
		end
		@submenu=options;
		$console.info("q. Cancel");
		@submenu.merge!({ 'q':->{@submenu={};} });
	end
	def confirm?(msg,default: nil)
		bool=nil;
		while true
			$console.warn("#{msg} [#{default==true ? 'Y':'y'}/#{default==false ? 'N':'n'}]");
			STDOUT.putc('> ');
			i=STDIN.getch.upcase;
			bool=true if i=='Y';
			bool=false if i=='N';
			if !default.nil?&&i.strip==''
				i=default ? 'Y':'N';
				bool=default;
			end
			break if !bool.nil?;
		end
		STDOUT.write(i+"\r\n");
		return bool;
	end
end

$input=InputConsole.new;

@rules={
};

STDIN.echo = false;
STDIN.raw!

at_exit{
	STDIN.echo = true;
	STDIN.cooked!
}

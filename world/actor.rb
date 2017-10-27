require('./math.rb');

class Task
	def self.idle;Task.new(:idle);end

	def type;@type;end
	def args;@args;end
	def obj;@obj;end

	#######
	private
	#######

	def initialize(type,*args,**obj)
		type="task_#{type}".to_sym;
		@type=type;
		@args=args;
		@obj=obj;
	end
end

class Traits
	# Proficiency for tasks
	def proficiency;@proficiency;end

	# Get traits directly if possible
	def method_missing(type)
		if @dict.key?type;
			return @dict[type];
		else
			super;
		end
	end

	def describe
		@dict.map{|k,v| "Trait #{k}: #{v}"}
	end

	#######
	private
	#######

	def initialize()
		@dict={
			sociable:rand(),   # sociable 		<-> isolated (social interactivity)
			impulsive:rand(),  # thoughtful 	<-> impulsive (thinking versus doing)
			smart:rand(),      # smartness		<-> dumbness (in this context, smartness means 'swift of thought.')
			carefree:rand()    # carefree		<-> anxious (in this context, how easy it is to let go of negative feelings)
		};

		@proficiency={
			move:0.9, # debug, this doesn't really make sense
			sleep:0.9
		};
	end
end

class Acquaintance
	def frustration;@frustration;end
	def relationship;@relationship;end
	def excitement;@excitement;end
	def similarity;@similarity;end

	def frustration=(v)
		@frustration=v.clamp(0,1);
	end
	def relationship=(v)
		@relationship=v.clamp(-1,1);
	end
	def excitement=(v)
		@excitement=v.clamp(0,1);
	end
	def similarity=(v)
		@similarity=v.clamp(0,1);
	end

	def describe;
		"f: #{@frustration} r: #{@relationship} e: #{@excitement} s: #{@similarity}"
	end

	def initialize()
		@frustration=ChangingValue.new(min:0, ratio:0.1);  # How frustrated we are with this person (0...)
		@relationship=ChangingValue.new(min:-1, max:1, ratio: 0.01); # How good a relationship this is (-1...1), 0 is neutral, -1 is enemies
		@excitement=ChangingValue.new(min:0, max:1, ratio: 0.1);   # How exciting this person is (makes a boost for the relationship levels (0...1))
		@similarity=RestrictedValue.new(min:0, max:1);   # How similar the person seems like to us, also makes a boost to the relationship levels (0...1)
	end
	def excite(boost=1)
		# clearing frustration too
		clearFrustration(boost);
		@excitement=(@excitement+0.3*boost).clamp(0,1);
	end
	def remindOfPerson()
		return ((@similarity+@relationship*3)/2-@frustration/2).clamp(0,1);
	end
	def getDisappointment()
		return ((2*@similarity+3*@excitement)/5).clamp(0,1);
	end
	def clearFrustration(boost=2)
		@frustration/=boost;
	end
end

class Relationships
	def actors;@actors;end
	def doWeKnow?(actor)
		return @actors.key?actor.name;
	end
	def weGreeted(actor)
		if !doWeKnow? actor
			# New acquaintance
			@actors[actor.name]=Acquaintance.new();
			@actors[actor.name].excite(2); # because of our new acquaintance
		else
			# Old acquaintance, excite a little (depending on our relationship)
			acq=@actors[actor.name];
			acq.excite(acq.remindOfPerson());
		end
	end
	def greetedBack(actor)
		acq=@actors[actor.name];
		acq.relationship+=acq.similarity+0.04; # just a small amount
		acq.excite(0.2);
	end
	def ignored(actor,boost=1)
		acq=@actors[actor.name];
		acq.relationship-=0.1*boost;
		acq.frustration+=acq.getDisappointment()*boost;
	end

	def describe;
		@actors.map{|name,acq|
			["#{name}:",acq.describe]
		}
	end

	def initialize()
		@actors={};
	end

	def clearFrustration(boost,actor: nil)
		@actors.each{|name,acq|
			if !actor||actor.name!=name
				acq.clearFrustration(boost);
			end
		}
	end

	#######
	private
	#######
end

class Actor
	@@list=[];

	@@brain_interval=2;
	@@smart_dampening=0.3;

	def self.list;@@list;end
	def self.generatename(length)
		alphabet=['sa','ni','to','ii','oo','ee','aa','be','r','lu','tu','u','a','o','y','e','mi','me','mu','li','as','el','ri','ba','ma','su','fa','lo','be','ro','ca','mo','ko','du'];
		name='';
		for i in 0..rand(2)+1+length
			name+=alphabet.sample;
		end
		return name.capitalize;
	end
	def self.generatenames()
		names=[];
		for w in 0..rand(2)+1
			names.push(self.generatename(rand(w*2)));
		end
		return names;
	end

	def brain_interval;@interval;end
	def brain_interval=(v);
		# Take into account the smartness trait of the owner.
		# This simulates physical differences in brains.
		# We have some set values we cannot exceed.
		smartness=@traits.smart;
		absolute=-(v*smartness);
		dampening=@@smart_dampening; # How much the value actually affects
		@brain_interval=v+absolute*dampening;
	end

	def describe;
		[
			"Name: #{self.fullname} (#{self.name})",
			"Location: #{self.location}",
			"Status: #{self.status}",
			"Relationships:",@relationships.describe,
			"Traits:",@traits.describe
		]
	end

	def name;@names[0];end
	def fullname;@names.join(' ');end

	def status;
		@currentTask.type;
	end

	def tasks;@tasks;end

	def location;@location;end
	def location=(place);
		$world.places[place].removeActor(self) if $world.places.key? place;
		@location=place;
		$world.places[place].putActor(self) if $world.places.key? place;
	end
	def knownplaces;@knownplaces;end
	def spatialfrustration;@spatialfrustration;end

	def relationships;@relationships;end

	def traits;@traits;end

	def initialize(names: self.class.generatenames(), location: nil, task: Task.idle)
		@names=names;
		@traits=Traits.new();
		@currentTask=task;
		@tasks=[];

		@relationships=Relationships.new();

		@knownplaces={};
		@location=location;
		@spatialfrustration={};

		@brain_frustration={};
		self.brain_interval=@@brain_interval;

		# BRAIN
		Thread.new{
			while true
				if $paused
					sleep 1;
					next;
				end

				$console.debug("#{self.name}: I think, therefore I am.");
				# Check if there are tasks to fulfill
				begin
					if !@tasks[0].nil?
						task=@tasks[0];
						$console.debug("#{self.name}: #{task.type}");
						# Try to fulfill this task
						if fulfillCurrentTask?
							# Task was fulfilled
							clearFrustration(@traits.carefree*5);
						else
							# Task wasn't fulfilled, wait for next turn
							frustrateOnTask(task);
						end
					else
						@currentTask=Task.idle;
						task_idle();
					end
				rescue StandardError => e
					$console.error("#{self.name} BRAIN: #{e}");
					$console.error("#{e.backtrace}");
				end
				sleep @brain_interval;
			end
		}

		@@list.push(self);
	end

	def move(place)
		addTask(:move,place.to_sym);
	end

	def knowsPlace?(place)
		return @knownplaces.key?place;
	end

	def greetings?(greeter)
		# An actor (greeter) requests to greet.
		# Check if we are already greeting
		if @currentTask.type==:task_greet
			if @currentTask.args[0]==greeter
				# Already greeting, ignore this and smile
				return true;
			else
				# Greeting someone else???
				return false;
			end
		end
		tasks=[:task_idle];
		if tasks.include?@currentTask.type
			# Yeah I have nothing better to do, let's greet them back!
			# drop other tasks related to talking
			@tasks=@tasks.reject{|task|
				rejected_types=[:task_greet,:task_greet_back];
				rejected_types.include?task.type;
			}
			addTask(:greet_back,greeter);
			return true;
		else
			$console.log("#{self.name} rejects because status is #{self.status}");
			# Heck off.
			return false;
		end
	end

	#######
	private
	#######
	
	# TASKS
	def task_greet(actor)
		$console.info("#{self.name}: Greet #{actor.name}");
		@relationships.weGreeted(actor);
		success=actor.greetings?(self);

		if success
			$console.debug("#{self.name} succeeded in greeting");
			@relationships.greetedBack(actor);
			# if we succeeded in greeting them, we can init a conversation :D
			addTask(:talk,actor);
		else
			$console.debug("#{self.name} was ignored");
			# :<
			@relationships.ignored(actor);
		end

		return true; # The task succeeds either way, even if we fail the greeting.
	end

	def task_greet_back(actor)
		$console.info("#{self.name}: Hey there #{actor.name}! :D");
		@relationships.weGreeted(actor);
		
		# assume that we can init a conversation with this actor now :D
		addTask(:talk,actor);
	end

	def task_talk(actor)
		# Check if the actor is in the same room, because if not, we got ignored >:C
		if actor.location!=@location
			$console.log("#{self.name}: >:C");
			@relationships.ignored(actor,2);
			return true;
		end
		$console.log("#{self.name}: Talk to #{actor.name}...");
		# wait for an answer for .... seconds, then try to continue the conversation
		addTask(:talk,actor);
	end

	def task_move(place)
		$console.info("#{self.name}: Move -> #{place}");

		if $world.places[@location].connections.include?(place)
			# go
			self.location=place;
			@knownplaces[place]=true;
		end

		# can't go if you don't know the place
		return false if (!knowsPlace?(place));

		self.location=place;
	end

	def task_idle()
		$console.log("#{self.name}: Idle...");
		# Idle around.

		# TODO: social interactions first (if social)
		otheractors=$world.places[@location].actors.select{|actor| actor!=self };

		$console.debug("#{self.name}: #{otheractors.length} actors in room");

		# Find an actor that we're not acquainted with yet
		otheractors.shuffle.each{ |actor|
			if !@relationships.doWeKnow?actor
				# let's get to know this actor!
				addTask(:greet,actor);
			end
		};

		# if the current room has places to go to, curiously check out a new place. (not very social)
		# if we have spent too much time in one room, go to another one to keep sane. (antisocial)
		frustrateincurrentlocation();
		if @spatialfrustration[@location]>1
			# Try and find a place to go to
			frustrations=$world.places[@location].connections.sort_by{|place| (@spatialfrustration[@place]||0) };
			#$console.debug("#{self.name}: Spatial frustrations: #{frustrations}");
			move(frustrations[0].to_sym);
		end
	end

	def frustrateincurrentlocation()
		@spatialfrustration[@location]=0 if !@spatialfrustration.key? @location;
		@spatialfrustration[@location]+=@traits.sociable**2;
		@spatialfrustration[@location]*=(2.0-@traits.carefree);
		$console.debug("#{self.name}: Frustrating in #{@location}! (#{@spatialfrustration[@location]})");
	end

	def frustrateOnTask(task)
		proficiency=@traits.proficiency[task.type];
		if (proficiency.nil?)
			$console.debug("No proficiency data for task #{task.type}, assuming .5");
			proficiency=0.5;
		end
		# A proficiency of 1 means we will never get frustrated - 0 means we're already fully frustrated on the first failure.
		# Increase frustration on the task - more frustration if less proficient.

		failures_allowed=3; # FIXME: arbitrary

		@brain_frustration[task.type]=0 if !@brain_frustration.key? task.type;
		@brain_frustration[task.type]+=(1.0-proficiency)+(1/failures_allowed);
		@brain_frustration[task.type]*=(2.0-@traits.carefree);

		$console.debug("#{self.name} frustrates on #{task.type}: #{@brain_frustration[task.type]}");

		if @brain_frustration[task.type]>1
			# Drop task
			dropCurrentTask();
		end
	end

	def clearFrustration(amount=0.5)
		@brain_frustration.each{ |k,v|
			@brain_frustration[k]=v/(1+amount);
		}
		@spatialfrustration.each{ |k,v|
			@spatialfrustration[k]=v/(1+amount);
		}
		@relationships.clearFrustration(1+amount);
	end

	def fulfillCurrentTask?()
		@currentTask=task=@tasks[0];
		success=false;
		if self.class.private_method_defined? task.type
			$console.debug("#{self.name}: Fulfilling task #{task.type}");
			obj=task.obj;args=task.args;
			if (obj=={})
				success=self.send(task.type,*args);
			else
				success=self.send(task.type,*args,**obj);
			end
			success=true if success==nil;
		else
			$console.error("#{self.name}: Unknown task #{task.type}");
		end
		if success
			$console.debug("#{self.name} task succeeded");
			dropCurrentTask();
		else
			$console.debug("#{self.name} task FAILED");
		end
		return success;
	end
	def dropCurrentTask()
		task=@tasks.shift();
		$console.debug("#{self.name} dropping task #{task.type}");
	end
	def addTask(type,*args,**obj)
		$console.debug("#{self.name} add task: #{type}");
		@tasks.push(
			Task.new(type,*args,**obj)
		);
	end
end

class Place
	def name;@name;end
	def size;@size;end

	def actors;
		Actor.list.select{ |item| item.location==@name }
	end

	def connections;@connections;end

	def describe;
		actors=self.actors;
		[
			"Name: #{@name}",
			"Pop: #{actors.length/@size}",
			"Actors: #{actors.map{|a| a.name}}"
		]
	end

	def removeActor(actor)
		@actors.delete(actor);
	end
	def putActor(actor)
		@actors.push(actor);
	end

	def initialize(name,size: 5, connections: [])
		@name=name;
		@size=size;
		@actors=[];
		@connections=connections;
	end
end

class World
	@@void=Place.new('void');
	def void;@@void;end
	def places;@places;end
	def initialize(places)
		@places={};
		places.each{ |name,opts|
			@places[name]=Place.new(name,**opts);
		};
	end
	def populate(place,count=1)
		for i in 0...count
			$console.info("Populating #{place}... [#{i+1}/#{count}]");
			Actor.new(location: place);
			sleep rand*0.1;
		end
	end
end

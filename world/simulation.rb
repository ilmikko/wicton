require('./console.rb');

require('./world.rb');
require('./actor.rb');

$paused=true;

$world=World.new({
	plaza:{
		size:20,
		connections:[:hall]
	},
	hall:{
		size:8,
		connections:[:room,:plaza]
	},
	room:{
		size:2,
		connections:[:closet,:hall]
	},
	closet:{
		size:1,
		connections:[:room]
	}
});

# start with a random number of actors in the plaza and see what happens
# drop actors with a slight random delay so that we won't be having them all 'think' in simultaneous instances
$world.populate(:plaza,1);
$world.populate(:room,1);

require('./userinteraction.rb');

sleep;

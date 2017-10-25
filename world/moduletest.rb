class Car
	def self.describe(car)
		if (car.is_a?Car)
			puts("This is a car. #{car} Is it broken? #{car.broken?}");
			puts("Are this cars wheels burst? #{car.wheel.burst?}");
		else
			puts("I can't describe #{car.class}, as it's not a car.");
		end
	end
	class Wheel
		@@burst_by_default=false;
		def burst?;!!@burst;end
		def spontaneousCombustion();
			puts("Boom! This car's tire has burst.");
			puts("Which car's?");
			# Problem: car is now broken. How do I switch @broken=true from here?
			@broken=true;
			@burst=true;
		end
		def initialize(burst: @@burst_by_default)
			@burst=burst;
		end
	end
	@@broken_by_default=false;
	def wheel;@wheel;end
	def broken?;@wheel.burst?;end
	def initialize(broken: @@broken_by_default)
		@broken=broken;
		@wheel=Wheel.new();
	end
end

car=Car.new();

brokencar=Car.new(broken: true);

carwithbrokenwheel=Car.new();

Car.describe(car);
Car.describe(brokencar);

Car.describe(carwithbrokenwheel);
carwithbrokenwheel.wheel.spontaneousCombustion();
Car.describe(carwithbrokenwheel);

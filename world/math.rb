class Numeric
	def sign; self < 0 ? -1 : 1; end
end

class RestrictedValue
	def /(number) set(get()/number);self end
	def *(number) set(get()*number);self end
	def +(number) set(get()+number);self end
	def -(number) set(get()-number);self end

	def inspect; get().to_s; end
	def to_s; get().to_s; end
	def to_i; get().to_i; end
	def to_f; get().to_f; end

	def coerce(other)
		if other.is_a? Integer
			[other,to_i]
		elsif other.is_a? Float
			[other,to_f]
		else
			raise TypeError, "#{self.class} can't be coerced into #{other.class}"
		end
	end

	#######
	private
	#######

	def set(value)
		@value=restrict(value);
	end
	def get()
		@value;
	end

	def restrict(val)
		if (@min!=nil&&@max!=nil)
			return val.clamp(@min,@max);
		elsif (@max!=nil)
			return val > @max ? @max : val;
		elsif (@min!=nil)
			return val < @min ? @min : val;
		end
	end

	def initialize(value=0, min: nil, max: nil)
		@min=min;
		@max=max;
		set(value);
	end
end

class ChangingValue < RestrictedValue
	@@functions={
		linear:->(x,delta){return x+delta;},
		square:->(x,delta){return x+delta.sign*delta**2;},
		isquare:->(x,delta){return x+delta.sign*(delta.abs**0.5);}
	}
	def get()
		super();
		return 0 if !@stamp;
		# calc the value for this before updating, as time has passed since the creation
		delta=(Time.now-@stamp); # seconds
		return restrict(
			@fallback.(@value,delta*@ratio)
		);
	end
	def set(value)
		super(value);
		@stamp=Time.now;
	end
	def initialize(value=0, ratio: 1, fallback: :linear, **args)
		super(value,**args);
		if !@@functions.key? fallback
			raise "Invalid fallback: #{fallback}";
		end
		@fallback=@@functions[fallback];
		@ratio=ratio;
	end
end

puts('Math.');

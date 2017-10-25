require('./math.rb');

num=ChangingValue.new(20, min:0, max:20, ratio:-20, fallback: :isquare);

require('./input.rb');
$input.listen({
	' ':->{
		num+=1;
	}
});

require('./screen.rb');

$xx=0;
$yy=$screen.height/2;

$x=0;

def graph(y)
	$screen.put($xx+$x,$yy-y,".");
end

while true
	graph(num);
	sleep 0.1;
	$x=($x+1) % $screen.width;
end

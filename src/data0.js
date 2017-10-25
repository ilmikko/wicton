const readline=require('readline'),rl=readline.createInterface({input:process.stdin,output:process.stdout});

var commands={
        help:function(_,v){
                if (v)
                        for (let g in commands) console.log(g+' - '+commands[g]);
                else
                        for (let g in commands) console.log(g);
        },
        setmode:function(_,m){
                m=parseInt(m);
                if (m>=0&&m<=2) {
                        brain.setMode(m);
                        return 0;
                }else return 1;
        }
};

rl.on('line',function(input){
        // Parse input
        if (input[0]=='!'){
                // Eval this
                let cmd=input.slice(1);
                try{
                        console.log(Function('return '+cmd)());
                }
                catch(err){
                        console.error(err);
                }
        }else if (input[0]=='/'){
                // Is a command
                let cmd=input.slice(1).split(' ');
                if (cmd[0] in commands){
                        if (commands[cmd[0]].apply(commands,cmd)) console.error('Command returned an error.');
                }
        }else{
                // Is text
                brain.process(input,function(err){
                        if (err) throw err;
                });
        }
});

rl.on('SIGINT',function(){
        process.exit();
});

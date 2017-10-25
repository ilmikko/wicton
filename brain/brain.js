// The BLACK BOX :o

global.memory=require('./memory.js');
global.nlu=require('./nlu.js');

module.exports={
        learningmode:0,
        setMode:function(mode){
                this.learningmode=mode;
                console.log("Setting learning mode to "+mode);
                if (mode>0) console.warn('Warning: blind learning mode has been set. ('+mode+')');
        },
        say:function(string){
                if (type(string)!=='string') return;

                memory.remember('messages',string);
                memory.remember('responses',string);
                console.log("> \x1b[34m"+string+"\x1b[0m");
        },
        learn:function(question,answer){
                memory.addConnection(question,answer);
                if (!question) question='';
                if (!answer) answer='';
                memory.learnWords(question+' '+answer);
        },
        tryToAnswer:function(question){
                // Okay, we don't know this but we need to reply somehow.
                // Start iterating through our known algorithms to pick the
                // most plausible answer to this question.
                var answers=nlu.findAnswers(question);
                var answer=Array.pick(answers.result);
                if (answer) {
                        // In case we're really not confident (c<0.5), we wait a while
                        // before sending. Vice versa, if we're really confident, say almost
                        // instantaneously.
                        var defaultDelay=1200,minimumDelay=750;
                        var ms=(-4*Math.pow(answers.confidence-0.5,3)+0.5)*2*defaultDelay+minimumDelay;
                        brain.wait(function(){
                                brain.say(answer);
                        },ms);
                }
        },
        process:function(question,error){
                memory.remember('questions',question);

                if (this.learningmode==2){
                        // We're just listening, learn a new connection
                        var previousQuestion=memory.recall('questions',2);
                        this.learn(previousQuestion,question);
                }else if (this.learningmode==1){
                        var previousMessage=memory.recall('messages');
                        this.learn(previousMessage,question);
                }

                memory.remember('messages',question);

                if (this.learningmode<2){
                        this.tryToAnswer(question);
                }
        },
        wait:function(f,d){
                if (this.waiting) clearTimeout(this.waiting);
                this.waiting=f;
                setTimeout(this.waiting,d);
        }
};

console.command.add('setmode',function(mode){
        brain.setMode(mode);
},{help:"Set brain mode\nUsage: setmode (0|1|2)\nTodo: More info on these modes"});

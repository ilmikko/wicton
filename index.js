const mongo=require('mongodb').MongoClient;

process.chdir(__dirname);

console.log("Dev version");

global.extend=function(a,b){for (let g in b) a[g]=b[g];return b;}

global.type=function type(o){
        var t=typeof o;
        if (t==='object'){
                if (o instanceof Array) return 'enumerable';
                else if (!isNaN(o.length)&&o.length>=0) return 'enumerable';
                else return t;
        }else return t;
}

require('./src/console.js');

global.data=require('./src/data.js');
global.brain=require('./brain/brain.js');

brain.setMode(1);

let url='mongodb://localhost:27017/wicton';
mongo.connect(url,function(err,db){
        if (err) throw err;

        db.close();
});

console.command.addmode('talk',function(input){
        if (input[0]=='/'){
                // Is a command
                let cmd=input.slice(1);
                console.command.modes['default'](cmd);
        }else brain.process(input);
});
console.command.chmode('talk');

console.command.add('say',function(){
        var string=[];
        Array.prototype.push.apply(string,arguments);
        string=string.join(' ');
        brain.process(string,function(err){
                if (err) throw err;
        });
},{help:'Say a string to Wicton.\nUsage: say [string]'});

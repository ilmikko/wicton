const fs=require('fs'),zlib=require('zlib');

function inflate(s){
        return JSON.parse(zlib.inflateSync(s));
}
function deflate(s){
        return zlib.deflateSync(JSON.stringify(s));
}

function upsert(name,target){
        // load file if it exists
        var filename='./data/'+name+'.bank';

        if (fs.existsSync(filename)){
                console.debug('Read file: '+filename);
                target[name]=inflate(fs.readFileSync(filename));
        }else{
                console.debug('New file: '+filename);
                target[name]={};
        }

        process.on('exit',function(){
                console.debug('Saving '+filename+'...');
                fs.writeFileSync(filename,deflate(target[name]));
        });

        return target[name];
}

var data=new Proxy({},{
        get:function(target,name){
                if (!(name in target)){
                        return upsert(name,target);
                }else return target[name];
        },
        set:function(target,name,value){
                if (!(name in target)) upsert(name,target);
                return target[name]=value;
        }
});

module.exports=data;

// A VERY basic browser - handles 300 requests and a bit more

const http=require('http'),https=require('https');

var browser={
        get:function(url,callback){
                https.get(url,function(res){
                        console.log('Response: '+res.statusCode);
                        console.log('Headers: '+JSON.stringify(res.headers));

                        if (res.statusCode<200){
                                //wait
                                console.warn('TODO: Status code was HTTP '+res.statusCode);
                        }else if (res.statusCode<300){
                                // OK
                                var data='';
                                res.on('data',function(chunk){
                                        data+=chunk;
                                });
                                res.on('end',function(){
                                        callback(data);
                                });
                        }else if (res.statusCode<400){
                                // redirect if possible
                                if (res.headers.location){
                                        console.log('Redirecting to '+res.headers.location+'...');
                                        browser.get(res.headers.location,callback);
                                }else{
                                        console.error('Unexpected: location header not found but status code was HTTP '+res.statusCode);
                                }
                        }else if (res.statusCode<500){
                                // client error (human operation required for now)
                                console.error('Browser client error: HTTP '+res.statusCode);
                        }else{
                                // some other unforeseen error
                                console.error('Browser encountered an unexpected error: HTTP '+res.statusCode);
                        }
                });
        }
};

module.exports=browser;

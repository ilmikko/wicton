// Provide the means for Wicton to seek information about things.

const browser=require('./browser.js');

var encyclopedia={

};

var subject="magpie";

browser.get('https://en.wikipedia.org/wiki/'+subject,function(html){
        console.log(html);
});

module.exports=encyclopedia;

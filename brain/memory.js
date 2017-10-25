// Handles memorizing things. Might forget sometimes.

const fs=require('fs');

Array.pick=function(arr){
        let len=arr.length;
        if (len==0) return;
        else return arr[Math.floor(Math.random()*len)];
}

var memory={
        preserve:false,// Whether or not temporary storage stays over sessions
        addWord:function(word,connections){
                if (!(word in data.words)) data.words[word]={o:0,c:{}};

                data.words[word].o++;

                var chars=word.split('');
                for (let char of chars){
                        this.addCharacter(char,chars);
                }

                // Give the nearest connections to this word better points in word connections
                var index=connections.indexOf(word);
                var wordconns=data.words[word].c;
                for (var g=0,glen=connections.length;g<glen;g++){
                        if (g==index) continue;
                        if (!(connections[g] in wordconns)) wordconns[connections[g]]=0;
                        // Normalized, so best words (next to our word) get a score nearest to 1
                        wordconns[connections[g]]+=Math.pow((connections.length-Math.abs(g-index))/connections.length,2);
                }
        },
        addCharacter:function(char,connections){
                if (!(char in data.characters)) data.characters[char]={o:0,c:{}};

                data.characters[char].o++;

                var index=connections.indexOf(char);
                var charconns=data.characters[char].c;
                for (var g=0,glen=connections.length;g<glen;g++){
                        if (g==index) continue;
                        if (!(connections[g] in charconns)) charconns[connections[g]]=0;
                        // Ditto, look above
                        charconns[connections[g]]+=(connections.length-Math.abs(g-index))/(connections.length);
                }
        },
        addConnection:function(question,answer){
                if (answer==null) return;
                console.log(question+'->'+answer);
                if (!this.knows(answer)) data.qa[answer]={o:1,a:[]};
                if (question!=null){
                        if (!this.knows(question))
                                data.qa[question]={o:1,a:[]};
                        else
                                data.qa[question].o++;

                        data.qa[question].a.push(answer);

                        nlu.addConnection(question);
                }
        },
        learnWords:function(string){
                var words=string.trim().split(/\s+|\-/);
                for (let word of words){
                        this.addWord(word,words);
                }
        },
        pickAnswer:function(question){
                if (this.knows(question)){
                        return Array.pick(this.getAnswersTo(question));
                }
        },
        knows:function(question){
                return question in data.qa;
        },
        getAnswersTo:function(question){
                if (!this.knows(question)) return [];
                return data.qa[question].a;
        },
        canAnswerTo:function(question){
                return this.knows(question)&&this.getAnswersTo(question).length!=0;
        },
        remember:function(section,str){
                if (!(section in data.temporary)) data.temporary[section]=[];
                data.temporary[section].push(str);
                return str;
        },
        recall:function(section,index=1){
                var arr=data.temporary[section];
                if (!arr||!arr.length) return;
                return arr[arr.length-index];
        }
};

if (!memory.preserve) data.temporary={}; else data.temporary;

module.exports=memory;

console.command.add('character',function(c){
        console.log('Character stats:');
        if (c==null){
                var chars=Object.keys(data.characters);
                console.log('Known characters: '+chars.length);
                console.log('Which are: '+chars.join(''));
        }else{
                c=c.toString()[0];
                if (c in data.characters){
                        console.log('Character '+c);
                        var o=data.characters[c];
                        var cons=Object.keys(o.c);
                        console.log('Hits: '+o.o);
                        console.log('Connections: '+cons.length);
                        console.log('Which are: '+cons.join(''));
                }else{
                        console.log('No character data for '+c);
                }
        }
});

console.command.add('word',function(c){
        console.log('Word stats:');
        if (c==null){
                var words=Object.keys(data.words);
                console.log('Known words: '+words.length);
        }else{
                if (c in data.words){
                        console.log('Word '+c);
                        var o=data.words[c];
                        var cons=Object.keys(o.c);
                        console.log('Hits: '+o.o);
                        console.log('Connections: '+cons.length);
                        console.log('Which are: '+cons.join(''));
                }else{
                        console.log('No word data for '+c);
                }
        }
});

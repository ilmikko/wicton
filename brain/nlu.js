function Algorithm(n,a,i){
        this.name=n;
        this.answer=a||function(){};
        this.insert=i||function(){};
        this.cached={};
}
extend(Algorithm,{
        data:{},
        prototype:{
                flushCache:function(){
                        this.cached={};
                        for (let question in data.qa) this.insert(question,data.qa[question]);
                }
        },
        add:function(n,a,i){
                var alg=new Algorithm(n,a,i);
                this.data[n]=alg;
                alg.flushCache();
        },
        addConnection:function(question){
                for (let alg in this.data){
                        this.data[alg].insert(question,data.qa[question]);
                }
        },
	answer:function(name,question){
		try{
			var a=this.data[name].answer(question)||[];
			if (type(a)!=='enumerable') a=[a];
			return a;
		}
		catch(err){
			console.error("Algorithm '%s' error: %s",name,err);
		}
	},
        answerAll:function(question){
                var results=[];
                for (let alg in this.data){
			results.push({name:alg,answer:this.answer(alg,question)});
                }
                var answers=[];
                for (let obj of results){
                        var name=obj.name,arr=obj.answer;
                        var alganswers=[];

                        if (arr){
                                if (type(arr)!=='enumerable') arr=[arr];
                                for (let result of arr){
                                        if (isNaN(result.confidence)||result.confidence<0) result.confidence=0;
                                        if (result.confidence>1) result.confidence=0.5;
                                        if (result.result.length==0) continue;

                                        alganswers.push(result);
                                }
                        }

                        console.log('Algorithm \''+name+'\': '+JSON.stringify(alganswers));
                        Array.prototype.push.apply(answers,alganswers);
                }

                if (answers.length==0) return {result:[],confidence:null};

                answers=answers.sort(function(a,b){return b.confidence-a.confidence;});

                var i=Math.floor(Math.pow(Math.random(),10)*answers.length);

                // Pick the most confident answer
                return {result:answers[i].result,confidence:answers[i].confidence};
        }
});

// Perfect match (nocase)
Algorithm.add('Perfectmatch',function(question){
        var q=question.trim().toUpperCase();
        if (q in this.cached) return [{confidence:0.9,result:this.cached[q].a}]; else return;
},function(k,v){
        this.cached[k.trim().toUpperCase()]=v;
});

// Perfect match (case w/o punctuation)
Algorithm.add('Nopunc Match',function(question){
        var q=question.trim().replace(/[!?.,'\-]/g,'');
        if (q in this.cached) return [{confidence:0.8,result:this.cached[q].a}]; else return;
},function(k,v){
        this.cached[k.trim().replace(/[!?.,'\-]/g,'')]=v;
});

// Match (nocase w/o punctuation or whitespace)
Algorithm.add('Barebone Match',function(question){
        var q=question.trim().replace(/[^a-zA-Z0-9]/g,'').toUpperCase();
        if (q in this.cached) return [{confidence:0.5,result:this.cached[q].a}]; else return;
},function(k,v){
        this.cached[k.trim().replace(/[^a-zA-Z0-9]/g,'').toUpperCase()]=v;
});

// Match (nocase w/o repeating characters)
Algorithm.add('Norepeat Match',function(question){
        var q=question.trim().toUpperCase().replace(/[^A-Z0-9]/g,'').replace(/([A-Z0-9])\1*/g,'$1');
        if (q in this.cached) return [{confidence:0.3,result:this.cached[q].a}]; else return;
},function(k,v){
        this.cached[k.trim().toUpperCase().replace(/[^A-Z0-9]/g,'').replace(/([A-Z0-9])\1*/g,'$1')]=v;
});

// Combined three (four?) matching algorithms
Algorithm.add('Fuzzy Match',function(question){
	var res=[];
	Array.prototype.push.apply(res,Algorithm.answer('Perfectmatch',question));
	Array.prototype.push.apply(res,Algorithm.answer('Nopunc Match',question));
	Array.prototype.push.apply(res,Algorithm.answer('Barebone Match',question));
	Array.prototype.push.apply(res,Algorithm.answer('Norepeat Match',question));
	return res;
});

// More than one sentences; later sentences are weighted, especially when ending with a question mark. Comprende?
Algorithm.add('DoubleTrouble',function(question){
	// Split question into sentences
	var sentences=question.split(/[.?!]+/)
		.map(function(a){return a.trim();})
		.filter(function(a){return !!a;});

	if (sentences.length<2) return; // This alg is useless with just one sentence

	var ii=sentences.length,i=ii,res=[];
	while(i--){
		// later sentences are weighted
		let weight=i+1;
		// Get fuzzy matches for all sentences
		let question=sentences[i];
		Array.prototype.push.apply(res,
			Algorithm.answer('Fuzzy Match',question).map(function(a){
				a.confidence*=weight/ii;
				return a;
			})
		);
	}
	return res;
},function(q,a){
	
});

// Perfect match but only with specific words (sliding match) (intensive but good)
Algorithm.add('Sliderspider',function(question){
        var words=question.trim().split(/\s+/);
        var o=this.cached,w;
        var confidence=0;
	var minconfidence=0; // DEBUG

        for (let word of words){
                confidence++;
                if (word in o){
                        w=o[word];
                        o=w.children;
                }else if (w) break; else return;
        }

	if (confidence<minconfidence) return;

        var ret=[];
        if (w.exact.length>0){
		// There were exact matches
                for (let g=0,glen=w.exact.length;g<glen;g++){
                        ret.push({confidence:0.9*(1/(-confidence*1.2-1)+1),result:w.exact[g].a});
                }
        }else{
		// Fuzzy matches
                for (let g=0,glen=w.all.length;g<glen;g++){
                        ret.push({confidence:0.7*(1/(-confidence*1.2-1)+1),result:w.all[g].a});
                }
        }
        return ret;
},function(k,v){
        var words=k.trim().split(/\s+/);
        var o=this.cached,w;
        for (let word of words){
                if (!(word in o)) o[word]={children:{},all:[],exact:[]};
                w=o[word];
                o=o[word].children;
                if (v.a.length>0) w.all.push(v); // Goes through all the generations
        }
        if (v.a.length>0) w.exact.push(v); // Goes only for the last one
});

module.exports={
        Algorithm:Algorithm,
        findAnswers:function(){
                return Algorithm.answerAll.apply(Algorithm,arguments);
        },
        addConnection:function(){
                return Algorithm.addConnection.apply(Algorithm,arguments);
        }
};

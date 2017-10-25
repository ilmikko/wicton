// Port to get data from the old wicton.mem

const fs=require('fs');

var data='';

try{
data=fs.readFileSync('./wicton.mem').toString();
}
catch(err){
console.error(err);
}

function addWord(id,word){
	if (!(id in wordbank)) wordbank[id]={count:0,originals:[]};
	wordbank[id].count++;
	wordbank[id].originals.push(word);
}

var wordbank={};
function learnWords(sentence){
	var words=sentence.trim().split(/\s+/);
	for (let word of words){
		var id=word.toLowerCase().replace(/is/g,'s').replace(/([A-Z])\1+/gi,'$1');
		addWord(id,word);

		// Also do without puncutation
		let wpid=id.replace(/[.,?!]/g,'');
		if (wpid==id) continue;
		addWord(wpid,word);
	}
}

lines=data.split(/\r?\n/);

console.log('Found '+lines.length+' lines');

var splitter=String.fromCharCode(1)+String.fromCharCode(2)+String.fromCharCode(1);

var qa_old=[];

for (let line of lines){
	line=line.split(splitter);
	var question=line[0],answer=line[1];
	if (!question||!answer) {
		console.warn('qa pair invalid: '+question+'->'+answer);
		continue;
	}
	qa_old.push({q:question,a:answer});
	learnWords(answer);
}

console.log('learned '+Object.keys(wordbank).length+' words');

var unknowns=[];
function reconstruct(question,oldanswer){
	if (!oldanswer) oldanswer='';

	var simplified=oldanswer.toLowerCase().replace(/is/g,'s').replace(/[!.,?\s]/g,'').replace(/([A-Z])\1+/gi,'$1');
	if (simplified===question){
		return oldanswer;
	}else{
		if (question in wordbank){
			var orig=wordbank[question].originals;
			if (orig.length==1) return orig[0]; else {
				unknowns.push({q:question,o:orig});
			}
		}else{
		}
	}
}

// Reconstruct sentences
var translate={};
for (let g=0,glen=qa_old.length;g<glen;g++){
	let qapair=qa_old[g]
	let prevans='';
	if (g-1>=0){ prevans=qa_old[g-1].a; }
	var recon=reconstruct(qapair.q,prevans);
	if (recon) {
		translate[qapair.q]=recon;
	}
}

console.log('Reconstructed '+Object.keys(translate).length+' sentences');

var newqa={};
for (let line of qa_old){
	var question=line.q,answer=line.a;
	if (!(question in translate)){
		console.log('Skipping '+question+'...');
	}else{
		var id=translate[question];
		if (!(id in newqa)) newqa[id]=[];
		newqa[id].push(answer);
	}
}

console.log('Final qa: '+Object.keys(newqa).length+' questions');

fs.writeFileSync('wicton.mem.bank',JSON.stringify(newqa));

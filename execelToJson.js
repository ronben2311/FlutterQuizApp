//extract data from excel to json format. 
//output questionList.dart

const fs = require('fs');
const XLSX = require('xlsx');

const workbook = XLSX.readFile('quizXlx.xlsx');
const worksheet = workbook.Sheets[workbook.SheetNames[0]];
const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

let output = '';

for (let i = 0; i < jsonData.length; i++) {
  const row = jsonData[i];
  if (row[0] && row[0].length > 0)
  {
    let question =  delChars(row[0]); // row[0].replace('"', '').replace("'", "").replace(/\r\n/g, ' ').replace(/\n/g, ' ').replace(/(\r\n|\n|\r)/gm, "");

    const options = row.slice(1, 5);
    const optionA = delChars(options[0]);
    const optionB = delChars(options[1]);
    const optionC = delChars(options[2]);
    const optionD = delChars(options[3]);

      // .map(option => option.replace(/\n/g, '\\n'));
    const correctAnswerIndex = options.findIndex((option, index) => (row[index + 5].trim() === 'X' || row[index + 5].trim() === 'x'));
  
    output += `QuizQuestion(
      question: \@@${formatRTLText(question)}\@@,
      answers: [
        QuizAnswer(answer: \@@${formatRTLText(optionA)}\@@),
        QuizAnswer(answer: \@@${formatRTLText(optionB)}\@@),
        QuizAnswer(answer: \@@${formatRTLText(optionC)}\@@),
        QuizAnswer(answer: \@@${formatRTLText(optionD)}\@@),
      ],
      correctAnswerIndex: ${correctAnswerIndex},
    ),\n`
  }
  
}

fs.writeFileSync('output.ts', output);

function formatRTLText(text) {
  return text; //'\u202B' + text + '\u202C';
}

function delChars(strToEdit){
  try {
    if (typeof strToEdit === 'string' && strToEdit)
    {
      strToEdit =  strToEdit.replace('"', '').replace("'", "").replace(/\r\n/g, ' ').replace(/\n/g, ' ').replace(/(\r\n|\n|\r)/gm, "").replace("`","'");
    
      return strToEdit.replace("'", '');
    }
    else {
      return '';
    }
  }
  catch (error) {
    console.error(error);
    
  }
 
}
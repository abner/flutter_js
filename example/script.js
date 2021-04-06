process.stdin.resume();
process.stdin.setEncoding('utf8');

var readline = require('readline');
var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.write('Olá mundo');
rl.on('line', function(line){
    console.log('LINE FROM NODEJS: ' + line);
});

setInterval(() => console.log('HI PERIODIC FROM NODEJS'), 2000);
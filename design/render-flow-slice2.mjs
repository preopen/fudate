import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:1960,height:1400,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/flow-vertical-slice-reservations.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1400));
await p.screenshot({path:'flow-vertical-slice-reservations.png',fullPage:true});
console.log('rendered flow-vertical-slice-reservations.png');
await b.close();console.log('DONE');

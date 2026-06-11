import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/redesign2-2-passsheet.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1200));
await p.screenshot({path:'redesign2-2-passsheet.png',fullPage:true});
console.log('rendered'); await b.close();

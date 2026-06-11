import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p1-wireframe-dayrail.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1000));
await p.screenshot({path:'p1-wireframe-dayrail.png',fullPage:true});
console.log('ok'); await b.close();

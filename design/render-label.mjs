import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:1340,height:760,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p2-wireframe-label-flow.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1100));
await p.screenshot({path:'p2-wireframe-label-flow.png',fullPage:true});
console.log('rendered'); await b.close();

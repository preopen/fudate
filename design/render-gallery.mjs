import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:1340,height:1400,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/overview-gallery.html',{waitUntil:'networkidle0',timeout:90000});
await new Promise(r=>setTimeout(r,1500));
await p.screenshot({path:'overview-gallery.png',fullPage:true});
console.log('rendered'); await b.close();

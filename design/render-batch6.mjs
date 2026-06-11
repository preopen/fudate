import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
// dayrail (tab device, fixed height)
let p=await b.newPage();
await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p1-wireframe-dayrail.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1100));
await p.screenshot({path:'p1-wireframe-dayrail.png',fullPage:true});
console.log('dayrail ok'); await p.close();
// direct booking (full page, taller)
p=await b.newPage();
await p.setViewport({width:1128,height:1200,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p3-wireframe-direct-booking.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1100));
await p.screenshot({path:'p3-wireframe-direct-booking.png',fullPage:true});
console.log('direct ok'); await p.close();
await b.close();console.log('DONE');

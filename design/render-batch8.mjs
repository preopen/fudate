import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
// modal (tab device)
let p=await b.newPage();
await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p2-wireframe-course-assign.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1000));
await p.screenshot({path:'p2-wireframe-course-assign.png',fullPage:true});
console.log('assign ok'); await p.close();
// mypage+email (full page)
p=await b.newPage();
await p.setViewport({width:1128,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/p3-wireframe-direct-mypage.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1000));
await p.screenshot({path:'p3-wireframe-direct-mypage.png',fullPage:true});
console.log('mypage ok'); await p.close();
await b.close();console.log('DONE');

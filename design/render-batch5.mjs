import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
// pilot page 2
let p=await b.newPage();
await p.setViewport({width:928,height:1200,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/pilot-onepager-p2.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1000));
await p.screenshot({path:'pilot-onepager-p2.png',fullPage:true});
console.log('pilot p2 ok'); await p.close();

// interactive prototype — drive it to verify JS
p=await b.newPage();
await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/prototype-interactive.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,900));
await p.screenshot({path:'proto-1-today.png'});
console.log('today view captured');
// switch to dishes
await p.click('[data-view="dishes"]'); await new Promise(r=>setTimeout(r,300));
await p.screenshot({path:'proto-2-dishes.png'});
console.log('dishes view captured');
// click the NOW subtask (s2 = 煮切り) and s3 to complete component -> should not yet complete dish
await p.click('[data-st="s2"]'); await p.click('[data-st="s3"]'); await new Promise(r=>setTimeout(r,300));
await p.screenshot({path:'proto-3-dishes-after.png'});
console.log('dishes after toggles captured');
// switch to staff
await p.click('[data-view="staff"]'); await new Promise(r=>setTimeout(r,300));
await p.screenshot({path:'proto-4-staff.png'});
console.log('staff view captured');
// verify counts changed via DOM
const frac=await p.$eval('#frac',e=>e.textContent);
console.log('done count now =',frac);
await p.close();
await b.close();console.log('DONE');

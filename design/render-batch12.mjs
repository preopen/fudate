import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of [
  {h:'p2-wireframe-fridge-lens.html',o:'p2-wireframe-fridge-lens.png',w:1240,ht:760},
  {h:'p2-wireframe-modes-settings.html',o:'p2-wireframe-modes-settings.png',w:1240,ht:900},
]){const p=await b.newPage();
  await p.setViewport({width:j.w,height:j.ht,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1000));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

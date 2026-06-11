import puppeteer from 'puppeteer';
const jobs=[
  {h:'p1-wireframe-dayrail-multiday.html',o:'p1-wireframe-dayrail-multiday.png'},
  {h:'p1-wireframe-calendar.html',o:'p1-wireframe-calendar.png'},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1000));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

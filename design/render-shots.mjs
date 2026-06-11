import puppeteer from 'puppeteer';
const jobs=[
  {h:'redesign2-3-oneaccent.html',o:'pilot-shot-now.png'},
  {h:'p1-wireframe-view-dishes.html',o:'pilot-shot-dishes.png'},
  {h:'p2-wireframe-service-board.html',o:'pilot-shot-service.png'},
  {h:'p4-wireframe-passview.html',o:'pilot-shot-pass.png'},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:1240,height:900,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1000));
  const el=await p.$('.tab');
  await el.screenshot({path:j.o});
  console.log('shot',j.o); await p.close();}
await b.close();console.log('DONE');

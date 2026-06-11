import puppeteer from 'puppeteer';
const jobs=[
  {h:'redesign-A-bigcard.html',o:'redesign-A-bigcard.png'},
  {h:'redesign-B-kanban.html', o:'redesign-B-kanban.png'},
  {h:'redesign-C-focus.html',  o:'redesign-C-focus.png'},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:1240,height:880,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1200));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

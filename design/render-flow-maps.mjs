import puppeteer from 'puppeteer';
const jobs=[
  {h:'flow-vertical-slice-modes.html',o:'flow-vertical-slice-modes.png',w:1960,ht:1400},
  {h:'flow-overview-map.html',o:'flow-overview-map.png',w:1560,ht:1200},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:j.w,height:j.ht,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1400));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

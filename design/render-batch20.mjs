import puppeteer from 'puppeteer';
const jobs=[
  {h:'p1-wireframe-view-dishes-liquidglass.html',o:'p1-wireframe-view-dishes-liquidglass.png'},
  {h:'p1-wireframe-view-staff-liquidglass.html',o:'p1-wireframe-view-staff-liquidglass.png'},
  {h:'p2-wireframe-close-flow-liquidglass.html',o:'p2-wireframe-close-flow-liquidglass.png'},
  {h:'p2-wireframe-reservation-hub-liquidglass.html',o:'p2-wireframe-reservation-hub-liquidglass.png'},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:1240,height:980,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1200));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

import puppeteer from 'puppeteer';
const jobs=[
  {h:'p0-wireframe-onboarding-liquidglass.html',o:'p0-wireframe-onboarding-liquidglass.png'},
  {h:'p1-wireframe-template-editor-liquidglass.html',o:'p1-wireframe-template-editor-liquidglass.png'},
  {h:'p0-wireframe-service-setup-liquidglass.html',o:'p0-wireframe-service-setup-liquidglass.png'},
  {h:'p0-wireframe-simulation-liquidglass.html',o:'p0-wireframe-simulation-liquidglass.png'},
  {h:'p1-wireframe-settings-home-liquidglass.html',o:'p1-wireframe-settings-home-liquidglass.png'},
];
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
for(const j of jobs){const p=await b.newPage();
  await p.setViewport({width:1240,height:980,deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/'+j.h,{waitUntil:'networkidle0',timeout:60000});
  await new Promise(r=>setTimeout(r,1200));
  await p.screenshot({path:j.o,fullPage:true}); console.log('rendered',j.o); await p.close();}
await b.close();console.log('DONE');

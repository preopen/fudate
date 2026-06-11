import puppeteer from 'puppeteer';
const jobs = [
  { html: 'p1-wireframe-template-editor.html', out: 'p1-wireframe-template-editor.png', width: 1100 },
  { html: 'p2-wireframe-haccp-checklist.html', out: 'p2-wireframe-haccp-checklist.png', width: 960 },
  { html: 'p1-wireframe-dashboard.html', out: 'p1-wireframe-dashboard.png', width: 1100 },
];
const browser = await puppeteer.launch({ args:['--no-sandbox','--disable-setuid-sandbox'] });
for (const j of jobs){
  const page = await browser.newPage();
  await page.setViewport({ width:j.width, height:900, deviceScaleFactor:2 });
  await page.goto('file://'+process.cwd()+'/'+j.html, { waitUntil:'networkidle0', timeout:60000 });
  await new Promise(r=>setTimeout(r,1200));
  await page.screenshot({ path:j.out, fullPage:true });
  console.log('rendered', j.out); await page.close();
}
await browser.close(); console.log('DONE');

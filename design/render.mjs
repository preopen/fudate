import puppeteer from 'puppeteer';
const jobs = [
  { html: 'competitive-positioning.html', out: 'competitive-positioning.png', width: 1120 },
  { html: 'p0-wireframe-todaytask.html', out: 'p0-wireframe-todaytask.png', width: 1040 },
];
const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
for (const j of jobs) {
  const page = await browser.newPage();
  await page.setViewport({ width: j.width, height: 900, deviceScaleFactor: 2 });
  await page.goto('file://' + process.cwd() + '/' + j.html, { waitUntil: 'networkidle0', timeout: 60000 });
  await new Promise(r => setTimeout(r, 1200)); // let webfont settle
  await page.screenshot({ path: j.out, fullPage: true });
  console.log('rendered', j.out);
  await page.close();
}
await browser.close();
console.log('DONE');

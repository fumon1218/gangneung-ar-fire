import asyncio,sys
from playwright.async_api import async_playwright
async def run(fake,gyro):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream',f'--use-file-for-fake-video-capture=/home/claude/site/{fake}'])
        ctx=await b.new_context(viewport={'width':400,'height':780},permissions=['camera'])
        pg=await ctx.new_page(); pg.on('pageerror',lambda e:print('ERR',e))
        if gyro=='1': await pg.add_init_script("setInterval(()=>window.dispatchEvent(Object.assign(new Event('deviceorientation'),{alpha:0,beta:90,gamma:0})),50);")
        await pg.goto('http://localhost:8765/st_test.html?train')
        await pg.wait_for_selector('#go:not(.hidden)',timeout=60000)
        await pg.click('#go'); await pg.wait_for_timeout(300); await pg.click('#szBanner')
        for i in range(80):
            await pg.wait_for_timeout(1000)
            tip=await pg.evaluate("document.getElementById('tip').textContent")
            if '불이 났' in tip: break
        print('tip',tip); await pg.wait_for_timeout(1500); await pg.screenshot(path='/home/claude/A0.png')
        await pg.click('#trYell',force=True); await pg.click('#trPin',force=True); await pg.wait_for_timeout(500)
        bb=await pg.locator('#trSpray').bounding_box(); await pg.mouse.move(bb['x']+50,bb['y']+50); await pg.mouse.down(); await pg.wait_for_timeout(2000)
        await pg.screenshot(path='/home/claude/A1.png'); await pg.mouse.up()
        print('tip2',await pg.evaluate("document.getElementById('tip').textContent"))
        await b.close()
asyncio.run(run(sys.argv[1],sys.argv[2]))

import asyncio,sys
from playwright.async_api import async_playwright
async def run(fake, out):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream',f'--use-file-for-fake-video-capture=/home/claude/site/{fake}'])
        ctx=await b.new_context(viewport={'width':450,'height':800},permissions=['camera'])
        pg=await ctx.new_page(); pg.on('pageerror',lambda e:print('ERR',e)); pg.on('console',lambda m: print('C',m.text[:160]) if m.type in('error','warning') and 'GL Driver' not in m.text and '404' not in m.text else None)
        await pg.goto('http://localhost:8765/st_test.html')
        await pg.wait_for_selector('#go:not(.hidden)',timeout=60000)
        await pg.click('#go')
        tip=''
        for i in range(80):
            await pg.wait_for_timeout(1500)
            tip=await pg.evaluate("document.getElementById('tip').textContent")
            if '불이 났' in tip: break
            if i%10==0: print('frames',await pg.evaluate('window.__frames'))
        await pg.wait_for_timeout(2500)
        print(fake,'| tip:',tip)
        await pg.mouse.move(400,200); await pg.mouse.down(); await pg.wait_for_timeout(1500)
        await pg.screenshot(path=out); await pg.mouse.up()
        await b.close()
asyncio.run(run(sys.argv[1],sys.argv[2]))

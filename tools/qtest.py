import asyncio,sys
from playwright.async_api import async_playwright
async def run(fake,course,st):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream',f'--use-file-for-fake-video-capture=/home/claude/site/{fake}'])
        ctx=await b.new_context(viewport={'width':400,'height':780},permissions=['camera'])
        pg=await ctx.new_page(); pg.on('pageerror',lambda e:print('ERR',e))
        await pg.add_init_script("localStorage.setItem('gnfire-ext','true')")
        await pg.goto('http://localhost:8765/st_test.html')
        await pg.wait_for_selector('#go:not(.hidden)',timeout=60000)
        await pg.click('#go'); await pg.wait_for_timeout(400)
        await pg.click({'yeonsu':'#goYeonsu','cheheom':'#goCheheom','yaoe':'#goYaoe'}[course])
        for i in range(60):
            await pg.wait_for_timeout(1000)
            if '출동' in await pg.evaluate("document.getElementById('tip').textContent"): break
        await pg.evaluate(f"__dbg.alarm({st})"); await pg.click('#mapClose',force=True)
        for i in range(60):
            await pg.wait_for_timeout(1000)
            t=await pg.evaluate("document.getElementById('tip').textContent")
            if '불이 났어요! 화면' in t or '꾹' in t: break
        print('tip',t); await pg.wait_for_timeout(1000); await pg.screenshot(path='/home/claude/Q0.png')
        await pg.mouse.move(200,420); await pg.mouse.down()
        for i in range(40):
            await pg.wait_for_timeout(1000)
            if not await pg.evaluate("document.getElementById('quiz').classList.contains('hidden')"): break
        await pg.mouse.up(); await pg.wait_for_timeout(800)
        await pg.screenshot(path='/home/claude/Q1.png'); print('quiz', await pg.evaluate("document.getElementById('qQ').textContent"))
        await b.close()
asyncio.run(run(sys.argv[1],sys.argv[2],sys.argv[3]))

import asyncio,sys
from playwright.async_api import async_playwright
async def run(fake,course):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream',f'--use-file-for-fake-video-capture=/home/claude/site/{fake}'])
        ctx=await b.new_context(viewport={'width':400,'height':780},permissions=['camera'])
        pg=await ctx.new_page(); pg.on('pageerror',lambda e:print('ERR',e))
        await pg.goto('http://localhost:8765/st_test.html')
        await pg.wait_for_selector('#go:not(.hidden)',timeout=60000)
        await pg.click('#go'); await pg.wait_for_timeout(500); await pg.screenshot(path='/home/claude/L0.png')
        await pg.click('#extBtn'); await pg.wait_for_timeout(600); await pg.screenshot(path='/home/claude/L1.png')
        conv="([x,y])=>{const r=document.getElementById('exSvg').getBoundingClientRect(),k=Math.min(r.width/360,r.height/420),ox=r.left+(r.width-360*k)/2,oy=r.top+(r.height-420*k)/2;return [ox+x*k,oy+y*k]}"
        async def P(x,y): return await pg.evaluate(conv,[x,y])
        # 1 pin
        a=await P(137,182); c=await P(60,190)
        await pg.mouse.move(*a); await pg.mouse.down(); 
        for t in range(1,11): await pg.mouse.move(a[0]+(c[0]-a[0])*t/10,a[1]+(c[1]-a[1])*t/10)
        await pg.mouse.up(); await pg.wait_for_timeout(600); await pg.screenshot(path='/home/claude/L2.png')
        # 2 nozzle
        a=await P(258,340); c=await P(272,344)
        await pg.mouse.move(*a); await pg.mouse.down()
        for t in range(1,16): await pg.mouse.move(a[0]+(c[0]-a[0])*t/15,a[1]+(c[1]-a[1])*t/15)
        await pg.mouse.up(); await pg.wait_for_timeout(600); await pg.screenshot(path='/home/claude/L3.png')
        # 3 hold
        a=await P(175,150); await pg.mouse.move(*a); await pg.mouse.down(); await pg.wait_for_timeout(1100); await pg.mouse.up(); await pg.wait_for_timeout(500)
        # 4 sweep
        a=await P(230,250); await pg.mouse.move(*a); await pg.mouse.down()
        for s in range(7):
            for t in range(10): await pg.mouse.move(a[0]+((t*8) if s%2==0 else (72-t*8)), a[1]); await pg.wait_for_timeout(20)
            if s==3: await pg.screenshot(path='/home/claude/L4.png')
        await pg.mouse.up(); await pg.wait_for_timeout(500); await pg.screenshot(path='/home/claude/L5.png')
        print('ext',await pg.evaluate("localStorage.getItem('gnfire-ext')"), await pg.evaluate("document.getElementById('exT').textContent"))
        await pg.click('#exBack'); await pg.wait_for_timeout(400)
        await pg.click('#goOut' if course=='out' else '#goIn')
        for i in range(60):
            await pg.wait_for_timeout(1000)
            tip=await pg.evaluate("document.getElementById('tip').textContent")
            if '출동' in tip: break
        await pg.wait_for_timeout(800); await pg.screenshot(path='/home/claude/L6.png'); print('tip',tip)
        await pg.wait_for_timeout(5000); await pg.screenshot(path='/home/claude/L7.png'); print('tip2',await pg.evaluate("document.getElementById('tip').textContent"))
        await b.close()
asyncio.run(run(sys.argv[1],sys.argv[2]))

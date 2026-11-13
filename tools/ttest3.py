import asyncio,sys
from playwright.async_api import async_playwright
async def run(mode):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
        pg=await b.new_page(viewport={'width':400,'height':800})
        pg.on('pageerror',lambda e:print('ERR',e))
        await pg.goto('http://localhost:8765/train_test.html')
        await pg.wait_for_selector('#go:not(.hidden)',timeout=90000)
        await pg.click('#go'); await pg.wait_for_timeout(2500)
        print(await pg.evaluate("__S.fire && [__S.fire.name, __S.fire.stand.x, __S.fire.stand.z]"))
        # 불 앞으로 순간이동, 불 쪽 바라보기
        await pg.evaluate("""(()=>{const f=__S.fire,P=__P(); P.position.set(f.stand.x,0,f.stand.z); const dx=f.p.x-f.stand.x, dz=f.p.z-f.stand.z; P.rotation.y=Math.atan2(dx,dz); __S.yaw=P.rotation.y+Math.PI;})()""")
        if mode=='1': await pg.click('#view')
        await pg.wait_for_timeout(1500)
        await pg.screenshot(path='/home/claude/V0.png'); print(await pg.evaluate("document.getElementById('tip').textContent"))
        if await pg.is_visible('#yell'): await pg.click('#yell',force=True)
        await pg.click('#pinBtn',force=True); await pg.wait_for_timeout(300)
        bb=await pg.locator('#spray').bounding_box(); await pg.mouse.move(bb['x']+50,bb['y']+50); await pg.mouse.down()
        page2=pg
        # 다른 손가락으로 쓸기는 어려움 -> 직접 yaw 흔들기
        for i in range(40):
            await pg.evaluate(f"__S.yaw += {0.08 if (i//4)%2==0 else -0.08}"); await pg.wait_for_timeout(100)
            if i==12: await pg.screenshot(path='/home/claude/V1.png')
        await pg.mouse.up(); await pg.wait_for_timeout(500)
        print(await pg.evaluate("[__S.fire&&__S.fire.hp, __S.cleared, __S.powder, document.getElementById('tip').textContent]"))
        await pg.screenshot(path='/home/claude/V2.png')
        await b.close()
asyncio.run(run(sys.argv[1]))

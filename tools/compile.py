import asyncio,base64
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
        pg=await b.new_page(); pg.on('pageerror',lambda e:print('ERR',e)); pg.on('console',lambda m: print('C',m.text[:150]) if m.type=='error' else None)
        await pg.goto('http://localhost:8765/compile.html')
        for i in range(170):
            await pg.wait_for_timeout(2000)
            out=await pg.evaluate('window.__out||null')
            if out: open('/home/claude/site/targets.mind','wb').write(base64.b64decode(out)); print('saved'); break
            if i%10==0: print('progress',await pg.evaluate('window.__p'))
        await b.close()
asyncio.run(main())

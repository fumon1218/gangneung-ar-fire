import asyncio,base64,sys
from playwright.async_api import async_playwright
async def main(ck):
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
        pg=await b.new_page(); pg.on('pageerror',lambda e:print('ERR',e))
        await pg.goto(f'http://localhost:8765/compile2.html?c={ck}')
        for i in range(400):
            await pg.wait_for_timeout(2000)
            out=await pg.evaluate('window.__out||null')
            if out: open(f'/home/claude/gangneung-ar-fire/targets_{ck}.mind','wb').write(base64.b64decode(out)); print(ck,'saved'); break
        await b.close()
asyncio.run(main(sys.argv[1]))

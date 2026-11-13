from PIL import Image, ImageDraw, ImageFont, ImageFilter
import qrcode
DPI=100; mm=lambda v:int(round(v/25.4*DPI))
W,H=mm(600),mm(1800)
FK='/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc'; FB='/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'
F=lambda p,s:ImageFont.truetype(p,s,index=1)
URL='https://fumon1218.github.io/gangneung-ar-fire/'
qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H,box_size=20,border=2); qr.add_data(URL); qr.make()
QR=qr.make_image(fill_color=(20,30,60),back_color='white').convert('RGB')
def grad(w,h,c1,c2):
    g=Image.new('RGB',(1,h)); 
    for y in range(h): t=y/(h-1); g.putpixel((0,y),tuple(int(c1[i]+(c2[i]-c1[i])*t) for i in range(3)))
    return g.resize((w,h))
def stroke_text(d,xy,t,f,fill,sw,sc,anchor='mm'): d.text(xy,t,font=f,fill=fill,anchor=anchor,stroke_width=sw,stroke_fill=sc)
def make(art,course,c1,c2,acc,stations,out):
    im=grad(W,H,c1,c2); d=ImageDraw.Draw(im)
    # 제목
    stroke_text(d,(W//2,mm(70)),'강릉분원 AR 소방 체험',F(FB,mm(40)),'white',mm(4),acc)
    stroke_text(d,(W//2,mm(175)),'불끄기 대작전',F(FK,mm(86)),(255,232,90),mm(12),(150,30,20))
    d.rounded_rectangle((mm(60),mm(250),W-mm(60),mm(310)),radius=mm(30),fill='white')
    d.text((W//2,mm(280)),course,font=F(FK,mm(34)),fill=acc,anchor='mm')
    # QR + 순서
    d.rounded_rectangle((mm(25),mm(335),W-mm(25),mm(785)),radius=mm(30),fill='white')
    qs=mm(250); im.paste(QR.resize((qs,qs),Image.NEAREST),(mm(40),mm(345)))
    d.text((mm(40)+qs//2,mm(612)),'QR을 찍어 시작!',font=F(FK,mm(25)),fill=acc,anchor='mm')
    steps=[('1','QR코드를 찍어요'),('2','아래 그림을 비춰요'),('3','화면을 꾹 눌러\n불을 꺼요!')]
    y=mm(370)
    for n,t in steps:
        x=mm(305); d.ellipse((x,y,x+mm(50),y+mm(50)),fill=acc); d.text((x+mm(25),y+mm(25)),n,font=F(FK,mm(32)),fill='white',anchor='mm')
        d.multiline_text((x+mm(60),y+mm(6)),t,font=F(FK,mm(25)),fill=(30,35,60),spacing=mm(3))
        y+=mm(80)
    d.text((W//2,mm(670)),'🐾 동물 친구를 골라 함께 불을 꺼요'.replace('🐾 ',''),font=F(FB,mm(30)),fill=(60,60,80),anchor='mm')
    d.text((W//2,mm(720)),stations,font=F(FK,mm(34)),fill=acc,anchor='mm')
    # 원화 (AR 인식 그림) 600x900
    a=Image.open(art).convert('RGB').resize((W-mm(40),int((W-mm(40))*1.5)),Image.LANCZOS)
    ax,ay=mm(20),mm(800); mask=Image.new('L',a.size,0); ImageDraw.Draw(mask).rounded_rectangle((0,0,a.width,a.height),radius=mm(30),fill=255)
    d.rounded_rectangle((ax-mm(8),ay-mm(8),ax+a.width+mm(8),ay+a.height+mm(8)),radius=mm(36),fill='white')
    im.paste(a,(ax,ay),mask)
    tag=F(FK,mm(28)); stroke_text(d,(W//2,ay+mm(40)),'▼ 이 그림을 휴대폰으로 비춰요 ▼',tag,'white',mm(5),acc)
    d.text((W//2,H-mm(38)),'강원특별자치도교육청특수교육원 강릉분원',font=F(FB,mm(26)),fill='white',anchor='mm')
    im.save(out); return im

import sys
OUT=[('out1.png','① 시작: 정문 간판 앞','연습하고 ②~⑤ 장소로 출발!'),
     ('out2.png','② 필로티 2층 창문','2층 모서리 창문을 올려다봐요'),
     ('out3.png','③ 계단 옆 큰 창','계단 옆 큰 유리창을 올려다봐요'),
     ('out4.png','④ 유리벽 커튼월','위쪽 유리벽을 올려다봐요'),
     ('out5.png','⑤ 옥상 정원','옥상 정원을 올려다봐요')]
IN=[('ina.png','ⓐ 바리스타 체험실','미라가 커피잔에 불을 붙여요'),
    ('inb.png','ⓑ 그린월','불새가 그린월 위를 날아요'),
    ('inc.png','ⓒ 비상대피 안내도','용암 골렘이 나타났어요'),
    ('ind.png','ⓓ 안전체험관','우주 보스를 막아요!')]
pages={'out':[],'in':[]}
import os
for k,(lst,c1,c2,acc,course) in {'out':(OUT,(255,140,40),(255,95,60),(225,70,30),'실외'),'in':(IN,(60,150,255),(40,90,220),(30,90,210),'실내')}.items():
    for f,name,hint in lst:
        if not os.path.exists(f): continue
        pages[k].append(make(f,name,c1,c2,acc,hint,'b_'+f))
for k in pages:
    p=pages[k]
    if p: p[0].save(f'X배너_불끄기대작전_{"실외" if k=="out" else "실내"}_600x1800.pdf',save_all=True,append_images=p[1:],resolution=DPI)
allp=pages['out']+pages['in']; tw=W//8
pv=Image.new('RGB',((tw+20)*len(allp),H//8),'white')
for j,p in enumerate(allp): pv.paste(p.resize((tw,H//8)),(j*(tw+20),0))
pv.save('preview.jpg',quality=88); print(len(allp))

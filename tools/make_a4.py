# A4 표식 카드 PDF: 장소 인식이 어려울 때 교사가 인쇄해 들고 다니는 대체 표식
import re, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from courses import COURSES as NEW
from PIL import Image, ImageDraw, ImageFont
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(R, 'index.html'), encoding='utf-8').read()
names = dict((int(a), b) for a, b in re.findall(r"(\d+): '([^']+)'", re.search(r"const STATION_NAME = \{(.*?)\};", src).group(1)))
st_of = {int(k): int(v) for k, v in re.findall(r"^  (\d+):\s+\{ st: (\d+),", src, re.M)}
FONT = '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'
F = lambda n: ImageFont.truetype(FONT, n, index=1)  # index 1 = KR
pages = []  # (코스, 장소, 이미지)
out_in = {1: "실외", 2: '실외', 3: '실외', 4: '실외', 5: '실외', 6: '실내', 7: '실내', 8: '실내', 9: '실내'}
pick = {1: 1}  # ① 출발은 배너
names.setdefault(1, '① 출발 (본부 배너)')
for k in sorted(st_of):
    if k >= 100: continue
    st = st_of[k]
    if st not in out_in: continue
    if st in (6, 7, 8, 9) and k >= 23: pick[st] = k  # 실내는 배너 우선
    pick.setdefault(st, k)
for st in sorted(pick): pages.append((out_in[st], names.get(st, str(st)), os.path.join(R, 'tools/targets', f'T{pick[st]}.jpg')))
for c in NEW.values():
    for st, nm, *_rest, photos in c['stations']:
        pages.append((c['name'], nm, os.path.join(R, 'tools/targets', [k for k, v in NEW.items() if v is c][0], photos[0][0] + '.jpg')))
DPI = 150; W, H = int(210 / 25.4 * DPI), int(297 / 25.4 * DPI); mm = DPI / 25.4
out = []
for course, name, img in pages:
    pg = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(pg)
    d.rectangle([0, 0, W, 32 * mm], fill=(255, 107, 43))
    d.text((15 * mm, 6 * mm), '불 끄기 대작전 · 대체 표식 카드', font=F(int(5 * mm)), fill='white')
    d.text((15 * mm, 14 * mm), f'[{course}] {name}', font=F(int(10 * mm)), fill='white')
    im = Image.open(img).convert('RGB'); iw, ih = im.size; bw, bh = W - 24 * mm, H - 80 * mm
    sc = min(bw / iw, bh / ih); im = im.resize((int(iw * sc), int(ih * sc)), Image.LANCZOS)
    pg.paste(im, ((W - im.width) // 2, int(38 * mm + (bh - im.height) / 2)))
    for y, t in ((H - 26 * mm, '장소에서 인식이 잘 안 될 때, 이 사진을 휴대폰 카메라로 비추면 같은 장소로 인식돼요.'), (H - 17 * mm, '강원특별자치도교육청특수교육원 강릉분원')):
        f = F(int(4.2 * mm)); w = d.textlength(t, font=f); d.text(((W - w) / 2, y), t, font=f, fill=(60, 60, 60))
    out.append(pg)
out[0].save(os.path.join(R, 'markers_a4.pdf'), save_all=True, append_images=out[1:], resolution=DPI)
print(len(pages), 'pages')

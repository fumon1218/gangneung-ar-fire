# 배지 스티커 A4 (지름 60mm 원형 12개): 악당 5종 + 소화기 박사 + 꼬마 소방관
import os
from PIL import Image, ImageDraw, ImageFont
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
F = lambda n: ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc', n, index=1)
DPI = 200; mm = DPI / 25.4; W, H = int(210 * mm), int(297 * mm)
items = [('dragon', '용을 이겼어요'), ('golem', '용암 골렘 이겼어요'), ('phoenix', '불새를 이겼어요'), ('boss', '우주 보스 이겼어요'), ('mummy', '미라를 이겼어요'), (None, '소화기 박사'), (None, '꼬마 소방관')]
seq = [items[i % len(items)] for i in range(12)]
pg = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(pg); D = int(60 * mm)
for i, (v, label) in enumerate(seq):
    cx = int((30 + (i % 3) * 75) * mm); cy = int((40 + (i // 3) * 70) * mm)
    d.ellipse([cx - D // 2, cy - D // 2, cx + D // 2, cy + D // 2], fill=(255, 207, 51), outline=(255, 122, 47), width=int(2.5 * mm))
    if v:
        im = Image.open(os.path.join(R, f'vil_{v}.webp')).convert('RGBA').resize((int(40 * mm), int(40 * mm)))
        pg.paste(im, (cx - im.width // 2, cy - im.height // 2 - int(6 * mm)), im)
    else:
        t = '🧯' if '소화기' in label else '🚒'
        f = F(int(14 * mm)); w = d.textlength('★', font=f); d.text((cx - w / 2, cy - int(20 * mm)), '★', font=f, fill=(255, 122, 47))
    f = F(int(4.6 * mm)); w = d.textlength(label, font=f); d.text((cx - w / 2, cy + int(14 * mm)), label, font=f, fill=(120, 50, 10))
f = F(int(4 * mm)); t = '불 끄기 대작전 배지 스티커 · 원형 60mm 라벨지에 인쇄 · 강릉분원'; d.text(((W - d.textlength(t, font=f)) / 2, H - int(12 * mm)), t, font=f, fill=(90, 90, 90))
pg.save(os.path.join(R, 'badges_a4.pdf'), resolution=DPI); print('ok')

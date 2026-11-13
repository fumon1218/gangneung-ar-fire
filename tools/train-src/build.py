# train.html 조립: python3 tools/train-src/build.py  (shell.html + main.js + part2.js + aud.js)
import os
d=os.path.dirname(os.path.abspath(__file__))+'/'
sh=open(d+'shell.html').read(); m=open(d+'main.js').read()
m=m.replace('/*PARTICLES*/',open(d+'part2.js').read()).replace('/*AUDIO*/',open(d+'aud.js').read())
open(d+'../../train.html','w').write(sh.replace('/*MAIN*/',m)); print('train.html written')

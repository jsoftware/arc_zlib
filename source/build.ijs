NB. build.ijs

writesourcex_jp_ '~Addons/arc/zlib/source';'~Addons/arc/zlib/zlib.ijs'

f=. 3 : 0
(jpath '~addons/arc/zlib/',y) (fcopynew ::0:) jpath '~Addons/arc/zlib/',y
)

f 'zlib.ijs'

f=. 3 : 0
(jpath '~Addons/arc/zlib/',y) fcopynew jpath '~Addons/arc/zlib/source/',y
(jpath '~addons/arc/zlib/',y) (fcopynew ::0:) jpath '~Addons/arc/zlib/source/',y
)

f 'manifest.ijs'
f 'history.txt'
f 'readme.txt'

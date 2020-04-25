load 'arc/zlib'

test=: 3 : 0
for_i. 1 10 100 1e4 1e6 1e8 do.
 b=. zlib_compress a=. i$a.
 c=. zlib_uncompress b
 assert. a-:c
 b=. zlib_compress a=. a.{~?.i#256
 c=. zlib_uncompress b
 assert. a-:c
end.
EMPTY
)

noz=: NOZLIB_jzlib_
test ''
NOZLIB_jzlib_=: 1
test ''
NOZLIB_jzlib_=: noz
4!:55 <'test noz'


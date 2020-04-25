NB. cover verbs for deflate stream with zlib wrapper

NB. zlib_compress
NB. zlib_uncompress

NB. section 2.2 of rfc 1950

NB. =========================================================
NB. when zlib shared object un-available

NB. encode zlib stream with 2 bytes header and 4 btyes tailing adler32 checksum
NB. x ignored except 0
zlib_encode_j=: 6&$: : (4 : 0)
(((16b78 1{a.);x) deflate y), be32 adler32 y
)

NB. decode zlib stream with 2 bytes header and 4 btyes tailing adler32 checksum
NB. x is ignored
zlib_decode_j=: 0&$: : (4 : 0)
assert. 16b78=a.i.{.y [ 'zlib header not16b78'
assert. 0=31|256#. |. a.i.|.2{.y [ 'zlib header checksum error'
assert. 0=2{(8#2)#:a.i.1{y [ 'zlib header FDICT not supported'
of=. inflate _4}.2}.y
assert. (_4{.y) -: be32 adler32 of
of
)

NB. =========================================================
NB. when zlib shared object available

zlib_encode_so=: 6&$: : (4 : 0)
len=. ,12+>.1.001*#y
buf=. ({.len)$' '
assert. 0= >@{. cdrc=. zcompress2 buf ; len ; y ; (#y) ; x
'buf len'=. 1 2{cdrc
({.len){.buf
)

zlib_decode_so=: 0&$: : (4 : 0)
if. 0=x do.
  datalen=. , f=. 2*#y
else.
  datalen=. , x
end.
data=. ({.datalen)#{.a.
if. 0~: rc=. >@{. cdrc=. zuncompress data;datalen;y;#y do.
  if. 0~:x do.
    assert. 0 [ 'zlib uncompression error'
  end.
  while. rc e. _5 do.
    datalen=. , f=. 2*f
    data=. ({.datalen)#{.a.
    rc=. >@{. cdrc=. zuncompress data;datalen;y;#y
  end.
  if. 0~:rc do.
    smoutput rc
    assert. 0 [ 'zlib uncompression error'
  end.
end.
({.2{::cdrc){.1{::cdrc
)

NB. =========================================================
NB. cover verbs

zlib_compress=: zlib_encode_so`zlib_encode_j@.NOZLIB
zlib_uncompress=: zlib_decode_so`zlib_decode_j@.NOZLIB

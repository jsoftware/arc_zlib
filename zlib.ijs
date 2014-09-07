coclass 'jzlib'

zlib=: IFUNIX{::'zlib1.dll';unxlib 'z'
NOZLIB=: 0=(zlib,' zlibVersion >',(IFWIN#'+'),' x')&cd ::0:''
zcompress2=: (zlib, ' compress2 >',(IFWIN#'+'),' i *c *x *c x i')&cd
zuncompress=: (zlib, ' uncompress >',(IFWIN#'+'),' i *c *x *c x')&cd
MAX_DEFLATE=: 16bffff
deflate=: 4 : 0
'wrapper level'=. 2{.(boxopen x),<6
if. (0=level) +. 0=#y do. cm=. 0
elseif. 256>#y do.
  if. (#y) = #~.y do.
    cm=. 0
  else.
    cm=. 1
  end.
elseif. do.
  cm=. 1
end.
if. 0=cm do.
  wrapper deflate_unc y
  return.
end.
lz=. lz_enc y
of=. , |."1 (8#2) #: a.i. wrapper
of=. of, 1 1 0
i=. 0
while. i<#lz do.
  if. 256 > a=. i{lz do.
    of=. of, fixed_huffman_code0 huff_encode a
  else.
    i=. i+1
    a=. i{lz
    code=. 257 + ix=. _1+ ({:"1 lz_length) I. 1+a
    of=. of, fixed_huffman_code0 huff_encode code
    if. bit=. (<ix,0){lz_length do.
      of=. of, |. (bit#2) #: a - (<ix,1){lz_length
    end.
    i=. i+1
    a=. i{lz
    code=. ix=. _1+ ({:"1 lz_distance) I. 1+a
    of=. of, (5#2) #: code
    if. bit=. (<ix,0){lz_distance do.
      of=. of, |. (bit#2) #: a - (<ix,1){lz_distance
    end.
  end.
  i=. i+1
end.
of=. of, fixed_huffman_code0 huff_encode 256
a.{~ #.@|.("1) _8[\ of
)
huff_encode=: 4 : 0
'bit code sym'=. x{~ ({:"1 x) i. y
(bit#2)#:code
)
deflate_unc=: 4 : 0
segments=. (-MAX_DEFLATE) <\ y
blocks=. x, ; 0&deflate_unc_block&.> }:segments
blocks, 1&deflate_unc_block >@{:segments
)
deflate_unc_block=: 4 : 0
n=. #y
(x{a.),(Endian 1&ic n),(Endian 1&ic 0 (26 b.) n), y
)
huffman_code=: 4 : 0
bl_count=. 0, }. <: #/.~ (i.>:>./y),y
code=. 0
next_code=. 0
maxb=. >./y
for_b. >:i. >./y do.
  code=. 2 * code + (b-1){bl_count
  next_code=. next_code, code
end.
huffcode=. 0 0$0
for_n. i. #y do.
  l=. n{y
  if. l do.
    huffcode=. huffcode, l, c=. l{next_code
    next_code=. (1+c) l}next_code
  end.
end.
huffcode=. huffcode,.(0~:y)#i.#y
if. 1=x do. /:~ huffcode end.
)
fixed_huffman_code0=: 0&huffman_code (144#8),(112#9),(24#7),(8#8)
fixed_huffman_code1=: 1&huffman_code (144#8),(112#9),(24#7),(8#8)
lz_length=: 0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 0
lz_length=: lz_length ,. 3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227 258

lz_distance=: 0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13
lz_distance=: lz_distance ,. 1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577
inflate=: 3 : 0
if=. 0$0
of=. ''
huff_buf=: , |."1 (8#2) #: a.i. y

lastblock=. 0
bf=. 0
bf_end=. 8*#y
while. (-.lastblock)*.bf_end> >.&.(%&8) bf do.
  lastblock=. 1=0{huff_buf
  bf=. 1+bf
  cmptype=. #.(bf+i._2){huff_buf
  bf=. 2+bf
  if. 0=cmptype do.
    oof=: of
    bf=. >.&.(%&8) bf
    len=. #.(bf+i._16){huff_buf
    assert. (-.(16+bf+i._16){huff_buf)=(bf+i._16){huff_buf [ 'uncompressed block length error'
    of=. of, (4+(bf%8)+i.len){y
    bf=. 32+bf+8*len
  elseif. cmptype e. 1 2 do.
    if. 2=cmptype do.
      HLIT=. 257 + 2#.(bf+i._5){huff_buf
      HDIST=. 1 + 2#.(5+bf+i._5){huff_buf
      HCLEN=. 4 + 2#.(10+bf+i._4){huff_buf
      clen=. 19#0
      order=. 16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15
      clen=. (2#. |.("1) _3]\ (14+bf+i.3*HCLEN){huff_buf) (HCLEN{.order)}clen
      clen_code1=: 1&huffman_code clen
      bf=. bf + 14 + 3 * HCLEN
      lit=. 0
      litdist=. 0$0
      while. (HLIT+HDIST)>#litdist do.
        'lit bf'=. clen_code1 huff_decode bf
        if. lit<16 do.
          litdist=. litdist, lit
        elseif. 16=lit do.
          litdist=. litdist, (3+2#.(bf+i._2){huff_buf)#{:litdist
          bf=. bf+2
        elseif. 17=lit do.
          litdist=. litdist, (3+2#.(bf+i._3){huff_buf)#0
          bf=. bf+3
        elseif. 18=lit do.
          litdist=. litdist, (11+2#.(bf+i._7){huff_buf)#0
          bf=. bf+7
        end.
      end.
      lit_code1=. 1&huffman_code HLIT{.litdist
      dist_code1=. 1&huffman_code HLIT}.litdist
    end.
    lit=. 0
    while. 256~:lit do.
      if. 1=cmptype do.
        'lit bf'=. fixed_huffman_code1 huff_decode bf
      else.
        'lit bf'=. lit_code1 huff_decode bf
      end.
      if. 256>lit do.
        of=. of, lit{a.
      end.
      if. 257>lit do. continue. end.
      'b l1'=. (lit-257){lz_length
      l2=. 0
      if. b do. l2=. 2#.(bf+i.-b){huff_buf end.
      len=. l1 + l2
      bf=. bf+b
      if. 1=cmptype do.
        dist=. 2#.(bf+i.5){huff_buf
        bf=. bf+5
      else.
        'dist bf'=. dist_code1 huff_decode bf
      end.
      'b l1'=. lz_distance {~ dist
      l2=. 0
      if. b do. l2=. 2#.(bf+i.-b){huff_buf end.
      dist=. l1 + l2
      bf=. bf+b
      of=. of, len$(-dist){.of
    end.
  elseif. do.
    assert. 0 [ 'invalid BTYPE'
  end.
end.
huff_buf=: ''
of
)
huffman_code=: 4 : 0
bl_count=. 0, }. <: #/.~ (i.>:>./y),y
code=. 0
next_code=. 0
maxb=. >./y
for_b. >:i. >./y do.
  code=. 2 * code + (b-1){bl_count
  next_code=. next_code, code
end.
huffcode=. 0 0$0
for_n. i. #y do.
  l=. n{y
  if. l do.
    huffcode=. huffcode, l, c=. l{next_code
    next_code=. (1+c) l}next_code
  end.
end.
huffcode=. huffcode,.(0~:y)#i.#y
if. 1=x do. /:~ huffcode end.
)
huff_decode=: 4 : 0
for_bit. ~.{."1 x do.
  t=. }."1 (bit={."1 x)#x
  if. (#t) > ix=. (0{"1 t) i. 2#.(y+i.bit){huff_buf do.
    (ix{1{"1 t),y+bit return.
  end.
end.
assert. 0 [ 'huff_decode'
)
lz_enc=: 3 : 0
if. 6>#y do. a.i. y return. end.
h=. hash3 y
of=. a.i. 3{.y
i=. 3
win=. 32768
maxmatch=. 258
while. (_2+#y)>i do.
  j=. 0
  if. (win>i-ix) *. (i-3) > ix=. ((i-3){.h) i: i{h do.
    j=. 1
    lookahead=. i}.y
    history=. ix}.i{.y
    while. ((#y)>i+j-1)*.(maxmatch>j) do.
      if. ((j-1){lookahead) = {:j$history do. j=. j+1 else. break. end.
    end.
    j=. j-1
  end.
  if. j>2 do.
    of=. of, 256, j, i-ix
    i=. i+j
  else.
    of=. of, a.i. i{y
    i=. i+1
  end.
end.
of, a.i. (i-#y){.y
)

hash3=: 3 : 0
a=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.y
b=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.}.y
c=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.2}.y
(#y){. , a,.b,.c
)
install=: 3 : 0
if. -. IFWIN do. return. end.
require 'pacman'
'rc p'=. httpget_jpacman_ 'http://www.jsoftware.com/download/', z=. 'winlib/',(IF64{::'x86';'x64'),'/zlib1.dll'
if. rc do.
  smoutput 'unable to download: ',z return.
end.
(<jpath'~bin/zlib1.dll') 1!:2~ 1!:1 <p
1!:55 ::0: <p
smoutput 'done'
EMPTY
)
ENDIAN=: ('a'={.2 ic a.i.'a')
be32=: ,@:(|."1)@(_4&(]\))^:ENDIAN@:(2&ic)
be32inv=: (_2&ic)@:(,@:(|."1)@(_4&(]\))^:ENDIAN)
adler32=: [: ({: (23 b.) 16&(33 b.)@{.) _1 0 + [: ((65521 | +)/ , {.) [: (65521 | +)/\. 1 ,~ a. i. |.
zlib_encode_j=: 6&$: : (4 : 0)
(((16b78 1{a.);x) deflate y), be32 adler32 y
)
zlib_decode_j=: 0&$: : (4 : 0)
assert. 16b78=a.i.{.y [ 'zlib header not16b78'
assert. 0=31|256#. |. a.i.|.2{.y [ 'zlib header checksum error'
assert. 0=2{(8#2)#:a.i.1{y [ 'zlib header FDICT not supported'
of=. inflate _4}.2}.y
assert. (_4{.y) -: be32 adler32 of
of
)
zlib_encode_so=: 6&$: : (4 : 0)
len=. ,12+>.1.001*#y
buf=. ({.len)$' '
assert. 0= zcompress2 buf ; len ; y ; (#y) ; x
({.len){.buf
)

zlib_decode_so=: 0&$: : (4 : 0)
if. 0=x do.
  datalen=. , f=. 2*#y
else.
  datalen=. , x
end.
data=. ({.datalen)#{.a.
if. 0~: rc=. zuncompress data;datalen;y;#y do.
  if. 0~:x do.
    assert. 0 [ 'zlib uncompression error'
  end.
  while. _5=rc do.
    datalen=. , f=. 2*f
    data=. ({.datalen)#{.a.
    rc=. zuncompress data;datalen;y;#y
  end.
  if. 0~:rc do.
    assert. 0 [ 'zlib uncompression error'
  end.
end.
data=. ({.datalen){.data
)
zlib_compress=: zlib_encode_so`zlib_encode_j@.NOZLIB
zlib_uncompress=: zlib_decode_so`zlib_decode_j@.NOZLIB
zlib_compress_z_=: zlib_compress_jzlib_
zlib_uncompress_z_=: zlib_uncompress_jzlib_

coclass 'jzlib'

zlib=: IFUNIX{::'zlib1.dll';unxlib 'z'
NOZLIB=: 0=(zlib,' zlibVersion >',(IFWIN#'+'),' x')&cd ::0:''
zcompress2=: (zlib, ' compress2 >',(IFWIN#'+'),' i *c *x *c x i')&cd
zuncompress=: (zlib, ' uncompress >',(IFWIN#'+'),' i *c *x *c x')&cd
MAX_DEFLATE=: 16bffff
DYNAMIC=: 0
MAXSTATIC=: 500
BLKSIZE=: 65536
deflate=: 4 : 0
'wrapper level'=. 2{.(boxopen x),<6
cm=. 1
if. (0=level) +. 0=#y do. cm=. 0
elseif. 256>:#y do.
  if. (#y) = #~.y do.
    cm=. 0
  end.
end.
if. 0=cm do.
  wrapper deflate_unc y
  return.
end.
if. (#y) <: #lz=. lz_enc y do.
  wrapper deflate_unc y
  return.
end.
if. MAXSTATIC < #lz do.
  numblk=. >.(#lz)%BLKSIZE
  cm=. DYNAMIC{1 2
  numblk=. #lx=. ~. (#lz),~ t1{~ (#~ (#t1)&>) [ (t1=. I. lz < 256) I. BLKSIZE*1+i.numblk
else.
  numblk=. 1
  lx=. ,#lz
end.
blk=. 0
of=. , |."1 (8#2) #: a.i. wrapper
i=. 0
while. blk<numblk do.
  of=. of, blk=numblk-1
  of=. of, (cm-1){1 0,:0 1
  assert. 256>i{lz
  if. 2=cm do.
    bs=. blk{ 0, lx
    bl=. blk{ - 2 -/\ 0, lx
    assert. bl>0
    assert. i=bs
    data=. (bs+i.bl){lz

    lit_data=. (A1=. i.286), (286>data)#data
    F1=. <: #/.~ lit_data
    F1=. (1) 256}F1
    bits1=. #&> F1 hcodes A1
    bits1=. bits1 * (F1>0)
    bits1=. (- +/*./\0=|.bits1)}.bits1
    bits1=. (257&{.)^:(257>#bits1) bits1
    lit_code0=. 0&huffman_code bits1

    dist_data=. (A2=. i.32), 300 -~ ((329>:data)*.(300<:data))#data
    F2=. <: #/.~ dist_data
    bits2=. #&> F2 hcodes A2
    bits2=. bits2 * (F2>0)
    bits2=. (- +/*./\0=|.bits2)}.bits2
    if. 0=#bits2 do.
      bits2=. ,1
    elseif. bits2-:,1 do.
      bits2=. 1 1
    end.
    dist_code0=. 0&huffman_code bits2

    litdist=. bits1,bits2
    assert. 16> litdist
    cls=. repeatcodelength litdist
    litdista=. (A3=. i.19), (19>cls)#cls
    F3=. <: #/.~ litdista
    bits3=. #&> F3 hcodes A3
    bits3=. bits3 * (F3>0)
    order=. 16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15
    bits3a=. order{bits3
    bits3a=. (- +/*./\0=|.bits3a)}.bits3a
    bits3a=. (4&{.)^:(4>#bits3a) bits3a
    clen_code0=. 0&huffman_code bits3
    clsh=. clen_code0 encodecodelength cls

    HLIT=. #bits1
    HDIST=. #bits2
    HCLEN=. #bits3a

    hdr=. |. (5#2) #: HLIT-257
    hdr=. hdr, |. (5#2) #: HDIST-1
    hdr=. hdr, |. (4#2) #: HCLEN-4
    hdr=. hdr, , |.("1) (3#2) #:("1 0) bits3a
    hdr=. hdr, clsh

    of=. of,hdr
  end.
  while. i< blk{lx do.
    if. 256 > a=. i{lz do.
      i=. i+1
      if. 1=cm do.
        of=. of, fixed_huffman_code0 huff_encode a
      else.
        of=. of, lit_code0 huff_encode a
      end.
    else.
      assert. (257 <: i{lz) *. (285 >: i{lz)
      code=. i{lz
      i=. i+1
      ix=. code - 257
      assert. (1000 <: i{lz) *. (2000 > i{lz)
      extra=. (i{lz) - 1000
      i=. i+1
      if. 1=cm do.
        of=. of, fixed_huffman_code0 huff_encode code
      else.
        of=. of, lit_code0 huff_encode code
      end.
      if. bit=. (<ix,0){lz_length do.
        of=. of, |. (bit#2) #: extra
      end.
      assert. (300 <: i{lz) *. (329 >: i{lz)
      code=. (i{lz) - 300
      ix=. code
      i=. i+1
      assert. (2000 <: i{lz)
      extra=. (i{lz) - 2000
      i=. i+1
      if. 1=cm do.
        of=. of, (5#2) #: code
      else.
        of=. of, dist_code0 huff_encode code
      end.
      if. bit=. (<ix,0){lz_distance do.
        of=. of, |. (bit#2) #: extra
      end.
    end.
  end.
  if. 1=cm do.
    of=. of, fixed_huffman_code0 huff_encode 256
  else.
    of=. of, lit_code0 huff_encode 256
  end.
  blk=. 1+blk
end.
a.{~ #.@|.("1) _8[\ of
)
repeatcodelength=: 3 : 0
first=. 1, (}.y) ~: }:y
rcode=. first # y
rcnt=. first #;.1 y
cls=. 0$0
for_i. i.#rcode do.
  if. 3>i{rcnt do.
    cls=. cls, (i{rcnt)#i{rcode
  else.
    if. 0~:i{rcode do.
      cls=. cls, i{rcode
      for_j. _6#\ 1#~<:i{rcnt do.
        if. j>2 do.
          cls=. cls, 16, 100+j-3
        else.
          cls=. cls, j#i{rcode
        end.
      end.
    else.
      for_j. _138#\ 1#~i{rcnt do.
        if. j>10 do.
          cls=. cls, 18, 100+j-11
        else.
          for_k. _10#\ 1#~j do.
            if. k>2 do.
              cls=. cls, 17, 100+k-3
            else.
              cls=. cls, k#0
            end.
          end.
        end.
      end.
    end.
  end.
end.
cls
)
encodecodelength=: 4 : 0
z=. 0$0
i=. 0
while. i<#y do.
  assert. 19>i{y
  z=. z, x&huff_encode i{y
  if. 16=i{y do.
    i=. i+1
    z=. z, |. (2#2) #: 100 -~ i{y
  elseif. 17=i{y do.
    i=. i+1
    z=. z, |. (3#2) #: 100 -~ i{y
  elseif. 18=i{y do.
    i=. i+1
    z=. z, |. (7#2) #: 100 -~ i{y
  end.
  i=. i+1
end.
z
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
hc=: 4 : 0
if. 1=#x do. y
else. ((i{x),+/j{x) hc (i{y),<j{y [ i=. (i.#x) -. j=. 2{./:x end.
)

hcodes=: 4 : 0
assert. x -:&$ y
assert. (0<:x) *. 1=#$x
assert. 1 >: L.y
w=. ,&.> y
assert. w -: ~.w
t=. 0 {:: x hc w
((< S: 0 t) i. w) { <@(1&=)@; S: 1 {:: t
)
hcbits=: 3 : 0
b=. #&> x hcodes y
)

huffman_code=: 4 : 0
bl_count=. 0, }. <: #/.~ (i.>:>./y),y
code=. 0
next_code=. 0
maxb=. >./y
for_b. >:i. maxb do.
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
of=. a.i. 2{.y
i=. 2
win=. 32768
maxmatch=. 258
while. (_2+#y)>i do.
  j=. 0
  if. (win>i-ix) *. i > ix=. (i{.h) i: i{h do.
    lookahead=. i}.y
    history=. ix}.i{.y
    j=. ((#y)-i) <. +/ *./\ (maxmatch{.lookahead)=maxmatch $ history
  end.
  if. j>2 do.
    of=. of, (enclength j), encdistance i-ix
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
enclength=: 3 : 0
ix=. <: +/({:"1 lz_length)<:y
code=. 257 + ix
ex=. y-(<ix,1){lz_length
assert. (0<:ex)*.(30>:ex)
code, 1000+ex
)
encdistance=: 3 : 0
ix=. <: +/({:"1 lz_distance)<:y
code=. 300 + ix
ex=. y-(<ix,1){lz_distance
assert. (0<:ex)*.(8191>:ex)
code, 2000+ex
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
  while. rc e. _5 do.
    datalen=. , f=. 2*f
    data=. ({.datalen)#{.a.
    rc=. zuncompress data;datalen;y;#y
  end.
  if. 0~:rc do.
    smoutput rc
    assert. 0 [ 'zlib uncompression error'
  end.
end.
data=. ({.datalen){.data
)
zlib_compress=: zlib_encode_so`zlib_encode_j@.NOZLIB
zlib_uncompress=: zlib_decode_so`zlib_decode_j@.NOZLIB
zlib_compress_z_=: zlib_compress_jzlib_
zlib_uncompress_z_=: zlib_uncompress_jzlib_

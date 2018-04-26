NB. =========================================================
NB. deflate
NB. x : wrapper header ; level
NB. y : string
deflate=: 4 : 0
'wrapper level'=. 2{.(boxopen x),<NOZLIB{6 1
NB. choose compression method
BTYPE=. 1
if. (0=level) +. 0=#y do. BTYPE=. 0
elseif. 256>:#y do.
  if. (#y) = #~.y do.
    BTYPE=. 0
  end.
end.
if. 0=BTYPE do.
  wrapper deflate_unc y
  return.
end.
lz=. level lz_enc y
NB. if. (#y) <: #lz=. lz_enc y do.
NB.   wrapper deflate_unc y
NB.   return.
NB. end.
if. MAXSTATIC < #lz do.
  numblk=. >.(#lz)%BLKSIZE
  BTYPE=. DYNAMIC{1 2
NB. partition into blocks
  numblk=. #lx=. ~. (#lz),~ t1{~ (#~ (#t1)&>) [ (t1=. I. lz < 256) I. BLKSIZE*1+i.numblk
else.
  numblk=. 1
  lx=. ,#lz
end.
blk=. 0
of=. , |."1 (8#2) #: a.i. wrapper
i=. 0
while. blk<numblk do.
  of=. of, BFINAL=. blk=numblk-1     NB. end_block
  of=. of, (BTYPE-1){1 0,:0 1  NB. 2 bits for BTYPE
  assert. 256>i{lz    NB. each block starts with a literal
  if. 2=BTYPE do.
NB. dynamic huffman coding header
    bs=. blk{ 0, lx           NB. block start position
    bl=. blk{ - 2 -/\ 0, lx   NB. block length
    assert. bl>0
    assert. i=bs
    data=. (bs+i.bl){lz

    lit_data=. (A1=. i.286), (286>data)#data
    F1=. <: #/.~ lit_data
    F1=. (1) 256}F1
NB. max bit length is 15
    whilst. 15<>./bits1 do.
      bits1=. F1 bitlen A1
      minbits=. <./F1-.0
      F1=. (1+minbits) (I.minbits=F1) } F1
    end.
    bits1=. (- +/*./\0=|.bits1)}.bits1
    bits1=. (257&{.)^:(257>#bits1) bits1
    lit_code=. /:~ def_code bits1

    dist_data=. (A2=. i.32), 300 -~ ((329>:data)*.(300<:data))#data
    F2=. <: #/.~ dist_data
NB. corner case, bitlen fialed if only one non-zero
    if. 0=+/0~:F2 do.
      bits2=. ,0
      dist_code=. ,:0 0 0
    else.
      if. 1=+/0~:F2 do.
        if. 1={.0~:F2 do.
          F2=. 1 (1)}0~:F2
        else.
          F2=. 1 (0)}0~:F2
        end.
      end.
NB. max bit length is 15
      whilst. 15<>./bits2 do.
        bits2=. F2 bitlen A2
        minbits=. <./F2-.0
        F2=. (1+minbits) (I.minbits=F2) } F2
      end.
      bits2=. (- +/*./\0=|.bits2)}.bits2
      dist_code=. /:~ def_code bits2
    end.

NB. combined bit length vectors of literal and distance huffman coding
    litdist=. bits1,bits2
    assert. 16> litdist
    cls=. repeatcodelength litdist
    litdista=. (A3=. i.19), (19>cls)#cls
    F3=. <: #/.~ litdista
NB. bit length should be 0-7, change F3 if necessary
    whilst. 7<>./bits3 do.
      bits3=. F3 bitlen A3
      minbits=. <./F3-.0
      F3=. (1+minbits) (I.minbits=F3) } F3
    end.
    order=. 16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15
    bits3a=. order{bits3
    bits3a=. (- +/*./\0=|.bits3a)}.bits3a
    bits3a=. (4&{.)^:(4>#bits3a) bits3a
    clen_code=. /:~ def_code bits3

NB. huffman code of code length sequence
    clsh=. clen_code encodecodelength cls

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
NB. dynamic huffman header ended here

  assert. 256>:i{lz [ 'first symbol is not a literal'
  while. i< blk{lx do.
    code=. i{lz
    assert. 285>:code [ 'not literal or length'
    assert. 256~:code [ 'EOB is illegal during encoding'
    of=. of, (lit_code&huff_encode)`(fixed_huffman_code&huff_encode)@.(1=BTYPE) code
    i=. i+1

    if. 257 <: code do.  NB. (length,distance) pair, see lz.ijs
      ix=. code - 257  NB. index ot lz_length table
      assert. (1000 <: i{lz) *. (2000 > i{lz)
      extra=. (i{lz) - 1000
      i=. i+1
      if. bit=. (<ix,0){lz_length do.
        of=. of, |. (bit#2) #: extra
      end.
NB. distance
      assert. (300 <: i{lz) *. (329 >: i{lz)
      code=. (i{lz) - 300
      ix=. code
      i=. i+1
      assert. (2000 <: i{lz)
      extra=. (i{lz) - 2000
      i=. i+1

      of=. of, (dist_code&huff_encode)`((5#2)&#:)@.(1=BTYPE) code
      if. bit=. (<ix,0){lz_distance do.
        of=. of, |. (bit#2) #: extra
      end.
    end.
  end.
NB. end of block delimiter
  of=. of, (lit_code&huff_encode)`(fixed_huffman_code&huff_encode)@.(1=BTYPE) 256
  blk=. 1+blk
end.
NB. each block does not ended in byte boundary, but deflate stream may need padding bits
a.{~ #.@|.("1) _8[\ of
)

NB. =========================================================
NB. compress code length sequence
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
NB. compress non-zero
      cls=. cls, i{rcode
      for_j. _6#\ 1#~<:i{rcnt do.
        if. j>2 do.
          cls=. cls, 16, 100+j-3
        else.
          cls=. cls, j#i{rcode
        end.
      end.
    else.
NB. compress zero
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

NB. =========================================================
NB. huffman code of code length sequence
encodecodelength=: 4 : 0
z=. 0$0
i=. 0
while. i<#y do.
  assert. 19>i{y
  z=. z, x&huff_encode i{y
NB. extra bits
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

NB. =========================================================
NB. x  huffman code table
NB. y  symbol
huff_encode=: 4 : 0
'bit code sym'=. x{~ ({:"1 x) i. y
(bit#2)#:code
)

NB. =========================================================
NB. deflate using un-compressed stream
NB. x  wrapper header
NB. y  string
deflate_unc=: 4 : 0
segments=. (-MAX_DEFLATE) <\ y
blocks=. x, ; 0&deflate_unc_block&.> }:segments
blocks, 1&deflate_unc_block >@{:segments
)

NB. =========================================================
NB. x 1=last block
deflate_unc_block=: 4 : 0
n=. #y
(x{a.),(Endian 1&ic n),(Endian 1&ic 0 (26 b.) n), y
)


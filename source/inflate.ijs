NB. =========================================================
NB. decode naked deflate stream
inflate=: 3 : 0
of=. ''
huff_buf=: , |."1 (8#2) #: a.i. y

BFINAL=. 0
bf=. 0
bf_end=. 8*#y
NB. ??? zlib produces stream without EOB for 16000#a. or 1000000#a.
NB. apparently EOB is used as a delimiter rather than terminator by zlib
NB. workaround by detecting end of stream
NB. header of each block is BFINAL BTYPE
while. (-.BFINAL)*.bf_end> >.&.(%&8) bf do.
  BFINAL=. 1=0{huff_buf
  bf=. 1+bf
  BTYPE=. #.(bf+i._2){huff_buf
  bf=. 2+bf
  if. 0=BTYPE do.    NB. no compression
    bf=. >.&.(%&8) bf  NB. skip to byte boundary
    len=. #.(bf+i._16){huff_buf
    assert. (-.(16+bf+i._16){huff_buf)=(bf+i._16){huff_buf [ 'uncompressed block length error'
    of=. of, (4+(bf%8)+i.len){y
    bf=. 32+bf+8*len
  elseif. BTYPE e. 1 2 do.
    if. 2=BTYPE do. NB. dynamic huffman
NB. section 3.2.6 of rfc 1951
      HLIT=. 257 + 2#.(bf+i._5){huff_buf
      HDIST=. 1 + 2#.(5+bf+i._5){huff_buf
      HCLEN=. 4 + 2#.(10+bf+i._4){huff_buf
      clen=. 19#0
      order=. 16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15
      clen=. (2#. |.("1) _3]\ (14+bf+i.3*HCLEN){huff_buf) (HCLEN{.order)}clen
      clen_code=: /:~ def_code clen  NB. huffman code table for header section
      bf=. bf + 14 + 3 * HCLEN
      lit=. 0
      litdist=. 0$0
      while. (HLIT+HDIST)>#litdist do.
        'lit bf'=. clen_code&huff_decode bf
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
      assert. 1<#HLIT{.litdist
      lit_code=. /:~ def_code HLIT{.litdist  NB.  HLIT bit length for literal
      if. 141=+/0~:HLIT{.litdist do.
      end.
      if. 1<#HLIT}.litdist do.
        dist_code=. /:~ def_code HLIT}.litdist   NB. remaining is bit length for distance
      else.
        dist_code=. ,:0 0 0
      end.
    end.
NB. section 3.2.3 of rfc 1951
    lit=. 0
    while. 256~:lit do.
      if. 1=BTYPE do.
        'lit bf'=. fixed_huffman_code&huff_decode bf
      else.
        'lit bf'=. lit_code&huff_decode bf
      end.
      if. 256>lit do.
        of=. of, lit{a.
      end.
      if. 257>lit do. continue. end.
NB. lz (length,distance) pair
NB. section 3.2.5 of rfc 1951
NB. length
      'b l1'=. (lit-257){lz_length
      l2=. 0
      if. b do. l2=. 2#.(bf+i.-b){huff_buf end.  NB. extra bit
      len=. l1 + l2
      bf=. bf+b
NB. distance
      if. 1=BTYPE do.
        dist=. 2#.(bf+i.5){huff_buf
        bf=. bf+5
      else.
        'dist bf'=. dist_code&huff_decode bf
      end.
      'b l1'=. lz_distance {~ dist
      l2=. 0
      if. b do. l2=. 2#.(bf+i.-b){huff_buf end.  NB. extra bit
      dist=. l1 + l2
      bf=. bf+b
NB. decoding lz77 (length,distance) pair with history buffer
      of=. of, len$(-dist){.of
    end.
  elseif. do. NB.
    assert. 0 [ 'invalid BTYPE'
  end.
end.
huff_buf=: '' NB. clean-up (buff_buf is a locale global)
of
)

NB. return alphabet, updated_index
NB. x      huffman code table assumed in prefix order
NB. y      index to huff_buf
NB. assume global huff_buf
huff_decode=: 4 : 0
for_bit. ~.{."1 x do.
  t=. }."1 (bit={."1 x)#x
  if. (#t) > ix=. (0{"1 t) i. 2#.(y+i.bit){huff_buf do.
    (ix{1{"1 t),y+bit return.
  end.
end.
assert. 0 [ 'huff_decode'
)

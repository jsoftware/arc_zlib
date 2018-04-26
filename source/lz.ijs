NB. similar to lz77 compression
NB. section 4 of rfc 1951

NB. symbols for 2 huffman trees
NB. 0 - 285      literal/length code
NB. 300 - 329    300 + distance code

NB. extra bits, not encoded by huffman
NB. 1000 - 1030  1000 + length - length of length code
NB. 2000 - 8191  2000 + distance - distance of distance code

NB. output stream:
NB. [ [0-255]+ [ [257-285][1000-1030][300-329][2000-8191] ]* ]* 256

NB. x is compression level
NB.   0 no compression
NB.   1 only compress text
NB.   >6  large sliding window
lz_enc=: 4 : 0
if. (0=x) +. 6>#y do. a.i. y return. end.
largewindow=. x>6
if. 1=x do.
  if. 0= textonly=. istext y do. a.i. y return. end.
end.
prelook=. largewindow{1024 4096  NB. pre lookup hash in blcok
sliding=. largewindow{4096 32768 NB. max sliding window
maxmatch=. 258  NB. max match length

h=. hash3 y
of=. a.i. 2{.y
i=. 2
win=. 0   NB. current size of sliding window. will grow up to sliding
winp=. 2  NB. starting index of fixed sliding window
winq=. 2  NB. starting index of variable sliding window
h1x=. h1=. h0=. 0$0
h0i=. h0&i:
while. (_2+#y)>i do.
  if. (i-winq)>:#h1 do.
    if. (sliding-prelook) > slen=. (#h0)+(#h1) do.
      h0=. h0, (winq+i.#h1){h
    else.
      h0=. (-(sliding-prelook)){.i{.h
      winp=. i-(sliding-prelook)
    end.
    h0i=. h0&i:
    h1=. prelook&{.^:(prelook<#) i}.h
    h1x=. h1 i: prelook&{.^:(prelook<#) i}.h
    winq=. i
  end.
  fnd=. 0
  if. (#h1x)> ix=. (i-winq){h1x do.
    if. ix<i-winq do. ix=. winq+ix [ fnd=. 1   NB.  lucky
    else.
      if. (#ht) > ixx=. (ht=. (i-winq){.h1) i: i{h do.
        ix=. winq+ixx [ fnd=. 1   NB.  less lucky, still found
      end.
    end.
  end.
  if. 0=fnd do.
    if. (#h0) > ix=. h0i i{y do.
      ix=. winp + ix [ fnd=. 1
    end.
  end.
  j=. 0
  if. fnd do.
    lookahead=. i}.y
    history=. ix}.i{.y
    j=. ((#y)-i) <. +/ *./\ (maxmatch{.lookahead)=maxmatch $ history
  end.
NB. minimum match length is 3 in deflate
  if. j>2 do.
    of=. of, (enclength j), encdistance i-ix
    i=. i+j
  else.
    of=. of, a.i. i{y
    i=. i+1
  end.
end.
NB. smoutput of, a.i. (i-#y){.y
NB. smoutput 'lz ratio ', ":(#of)%#y
of, a.i. (i-#y){.y
)

hash3=: 3 : 0
a=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.y
b=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.}.y
c=. , _2&ic("1) _4{.("1) _3]\ (>.&.(%&3)#y){.2}.y
(#y){. , a,.b,.c
)

NB. length as code+extra
NB. offset extra above 285
enclength=: 3 : 0
NB. beware off by one error
ix=. <: +/({:"1 lz_length)<:y
code=. 257 + ix
ex=. y-(<ix,1){lz_length
assert. (0<:ex)*.(30>:ex)
code, 1000+ex
)

NB. distance as code+extra
NB. offset both code and extra
encdistance=: 3 : 0
NB. beware off by one error
ix=. <: +/({:"1 lz_distance)<:y
code=. 300 + ix
ex=. y-(<ix,1){lz_distance
assert. (0<:ex)*.(8191>:ex)
code, 2000+ex
)

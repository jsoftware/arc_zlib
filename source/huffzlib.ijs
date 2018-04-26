NB. zlib specific huffman coding

NB. section 3.2.2 of rfc 1951

NB. =========================================================
NB.! from J Programming forum
NB.! contributed by Raul Miller

bl_count=: 3 :0 NB. y is result of freqs
0,}.<:#/.~(,~ [: i. 1 + >./)y
)

start_vals=: +:@+/\.&.|.@}:@,~&0

NB. y   bit length of each symbol
find_codes=: 3 :0 NB. y is result of freqs
b=. bl_count y
v=. start_vals b
n=. /:~ ~.y-.0
o=. ;({./.~ /:~ (</. i.@#)) y-.0
c=. ;<"1&.>n (([#2:) #: ])&.> (*b)#v+&.>i.&.>b
c /: o
)

NB. An alternate version of the result from find_codes would be given by:

NB. return  huffman code table, each row is bits,huffman_code,symbol_index
NB.         sorted by index of non-zero frequency symbol
NB. y       bit length of each symbol
def_code=: 3 :0
assert. 1<+/0~:y
b=. bl_count y
v=. start_vals b
n=. /:~ ~.y-.0
o=. ;({./.~ /:~ (</. i.@#)) y-.0
c=. ;n,.&.>(*b)#v+&.>i.&.>b
NB. z=. (,. i.@#)c /: o
z=. (I.0~:y),.~ c /: o
test_rule z
z
)

NB. x and y same as that for hcodes
NB. return  bit length of each symbol
bitlen=: 4 :0
assert. 1<+/0~:x
b=. 0~:x
b #inv #@>(b#x) hcodes b#y
)

NB. =========================================================

NB. test if huffman code can satify rule 1 of rfc 1951
NB. y  output from def_code
test_rule=: 3 : 0
for_i. ~. {."1 y1=. y/:({:"1 y) do.
  s=. (i={."1 y1) # (1{"1 y1)
  assert. (({.s)+i.#s) -: s   NB. rule 1
end.
)

NB. pre-compute fixed huffman codes
fixed_huffman_code=: /:~ def_code (144#8),(112#9),(24#7),(8#8)

NB. table for encoding and decoding
NB. section 3.2.5 of rfc 1951
NB. extra bits for encoding length
lz_length=: 0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 0
lz_length=: lz_length ,. 3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227 258

NB. extra bits for encoding distance
lz_distance=: 0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13
lz_distance=: lz_distance ,. 1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577

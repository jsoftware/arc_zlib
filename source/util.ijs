
NB. =========================================================
NB. download and install zlib1.dll for windows
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

NB. =========================================================
ENDIAN=: ('a'={.2 ic a.i.'a')

NB. big endian 4-byte integers
be32=: ,@:(|."1)@(_4&(]\))^:ENDIAN@:(2&ic)
be32inv=: (_2&ic)@:(,@:(|."1)@(_4&(]\))^:ENDIAN)

NB. =========================================================
NB. zlib block checksum
adler32=: [: ({: (23 b.) 16&(33 b.)@{.) _1 0 + [: ((65521 | +)/ , {.) [: (65521 | +)/\. 1 ,~ a. i. |.

NB. =========================================================
NB. test if data is text or binary
istext=: 3 : 0
if. +./(a.{~9 10 13, 32+i.224) e. y do.
  if. 0=+./(a.{~0 1 2 3 4 5 6, 14+i.18) e. y do.
    1 return.
  end.
end.
0
)

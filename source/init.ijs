NB. init.ijs

coclass 'jzlib'

3 : 0''
zlib=: (IFUNIX+UNAME-:'Darwin'){::'libz-ng1.dll';'libz-ng.2.so';'libz-ng.2.dylib'
NOZLIB=: 0=(zlib,' zlibng_version >',(IFWIN#'+'),' x')&cd ::0:''
if. 0=NOZLIB do.
  zcompress2=: (zlib, ' zng_compress2  ',(IFWIN#'+'),' i *c *x *c x i')&cd
  zuncompress=: (zlib, ' zng_uncompress  ',(IFWIN#'+'),' i *c *x *c x')&cd
else.
  zlib=: IFUNIX{::'zlib1.dll';unxlib 'z'
  NOZLIB=: 0=(zlib,' zlibVersion >',(IFWIN#'+'),' x')&cd ::0:''
  zcompress2=: (zlib, ' compress2  ',(IFWIN#'+'),' i *c *x *c x i')&cd
  zuncompress=: (zlib, ' uncompress  ',(IFWIN#'+'),' i *c *x *c x')&cd
end.
''
)

NB. the following only applies to compression done using J scripts.

NB. block size for uncompressed
MAX_DEFLATE=: 16bffff   NB. block size for uncompressed (BTYPE=0)

DYNAMIC=: 1      NB. should now work
MAXSTATIC=: 100  NB. some overhead of dynamic huffman coding
BLKSIZE=: 65536  NB. arbitrary block size for huffman coding

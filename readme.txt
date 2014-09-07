This zlib addon requires zlib to encode and decode zlib/deflate streams.  
When zlib is un-available, it will use pure J scripts which is much less
efficient.

For Linux, zlib should already installed by default in most distros.
If not, install using (debian and its dervitives) in terminal.

$ sudo aptitude install zlib1g

For Windows, type the following in a J session to install zlib dll.

load 'arc/zlib'
install_jzlib_''
load 'arc/zlib'

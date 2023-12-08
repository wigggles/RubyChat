# Ruby CLI-Chat Client/Server

Ensure you have Ruby installed.

This is a basic example of how a TCP server socket can be created for running a CLI or Gosu window chat service. It contains a server.rb and a client.rb Ruby script for running and maintaining an interface for a chat system. Client sessions have managed data set up as string byte blocks to provide and example of how to package an array of data for transmission. Additionally the chat when running in ApplicationWindow mode utilizing Gosu, a GameWorld is managed with WorldObjects shared between server client sessions.

### Start Server
```ruby
ruby server.rb
```
Server will log out client activity.

### Start one/many clients
```ruby
ruby client.rb <username>
```
>User name can not contain any spaces.

Type into the console and start chatting with other clients connected to the server.

To shut down either the server or a client, just close the terminal window.

### Helpful Documentation Links

https://ruby-doc.org/3.2.2/

[Ruby TCPSocket object](https://ruby-doc.org/3.2.2/exts/socket/TCPSocket.html) \
[Ruby UDPSocket object](https://docs.ruby-lang.org/en/2.2.0/UDPSocket.html) \
[Socket Basics](https://docs.oracle.com/cd/E19120-01/open.solaris/817-4415/sockets-18552/index.html) \
[Socket Message](https://manpages.ubuntu.com/manpages/noble/en/man2/recv.2.html) \
[How to get Public IP](https://stackoverflow.com/questions/13270042/get-public-remote-ip-address) \
[Net::HTTP, Net::HTTPS, and Net::FTP](https://ruby-doc.org/stdlib-2.6.3/libdoc/open-uri/rdoc/OpenURI.html)


## Notes on TCP sockets

A "safe" ball park for max payload that can be sent in a single package using TCP sockets is 1024 bytes (1 KiB).

Maximum theoretical size of a TCP packet is 64K (65535 bytes). Package size gets restricted by the Maximum Transmission Unit (MTU) of network resources. MTU is the maximum size of the data transfer limit set by hardware in a network. Keep in mind that Ethernet MTU is 1500 bytes, the IP header is normally 20 bytes, and TCP header which is at least 20.

## Default Common TCP and UDP Ports

* SMTP - 25  'Simple Mail Transfer Protocol' 
* HTTP - 80  'Hypertext Transfer Protocol' 
* HTTPS - 443 SSL (Secure Socket Layer) HTTP 
* FTP - 20, 21 "File Transfer Protocol"
    - Port 20 FTP active mode
    - Port 21 FTP signaling for mode
* TELNET - 23 Virtual terminal protocol to make a connection with the server TCP/IP protocol 
* IMAP - 143 'Internet Message Access Protocol' application Layer of a TCP/IP Model 
* RDP - 3389 'Remote Desktop Protocol' 
* SSH - 22 'Secure Shell' 
* DNS - 53 'Domain Name System' 
* DHCP - 67, 68 'Dynamic Host Configuration Protocol'
    - UDP Port 67 accepts address requests from DHCP and sending the data to the server
    - UDP Port 68 responds to all the requests of DHCP and forwards data to the client
* POP3 - 110 'Post Office Protocol' Version 3

### Things Yet To Do

* Client authentication management
* Client/Server graceful shutdowns
* Gosu Game
* UDP sockets
* ZeroMQ stuff maybe


## Ruby pack string op flags

[Ruby Packed data](https://ruby-doc.org/3.2.2/packed_data_rdoc.html) \
[How to use Ruby pack() unpack()](https://www.rubyguides.com/2017/01/read-binary-data)

Integer Directive   | Array Element | Meaning
:------------------:|:--------------|:--------------------------------------------------
C         | Integer | 8-bit unsigned (unsigned char)
S         | Integer | 16-bit unsigned, native endian (uint16_t)
L         | Integer | 32-bit unsigned, native endian (uint32_t)
Q         | Integer | 64-bit unsigned, native endian (uint64_t)
‌‌          |         |
c         | Integer | 8-bit signed (signed char)
s         | Integer | 16-bit signed, native endian (int16_t)
l         | Integer | 32-bit signed, native endian (int32_t)
q         | Integer | 64-bit signed, native endian (int64_t)
‌‌          |         |
S_, S!    | Integer | unsigned short, native endian
I, I_, I! | Integer | unsigned int, native endian
L_, L!    | Integer | unsigned long, native endian
‌‌          |         |
s_, s!    | Integer | signed short, native endian
i, i_, i! | Integer | signed int, native endian
l_, l!    | Integer | signed long, native endian
‌‌          |         |
S> L> Q>  | Integer | same as the directives without ">" except
s> l> q>  |         | big endian
S!> I!>   |         | (available since Ruby 1.9.3)
L!>       |         | "S>" is same as "n"
s!> i!>   |         | "L>" is same as "N"
l!>       |         |
‌‌          |         |
S< L< Q<  | Integer | same as the directives without "<" except
s< l< q<  |         | little endian
S!< I!<   |         | (available since Ruby 1.9.3)
L!<       |         | "S<" is same as "v"
s!< i!<   |         | "L<" is same as "V"
l!<       |         |
‌‌          |         |
n         | Integer | 16-bit unsigned, network (big-endian) byte order
N         | Integer | 32-bit unsigned, network (big-endian) byte order
v         | Integer | 16-bit unsigned, VAX (little-endian) byte order
V         | Integer | 32-bit unsigned, VAX (little-endian) byte order
‌‌          |         |
U         | Integer | UTF-8 character
w         | Integer | BER-compressed integer


Float Directive     |               | Meaning
:------------------:|:--------------|:--------------------------------------------------
D, d      | Float   | double-precision, native format
F, f      | Float   | single-precision, native format
E         | Float   | double-precision, little-endian byte order
e         | Float   | single-precision, little-endian byte order
G         | Float   | double-precision, network (big-endian) byte order
g         | Float   | single-precision, network (big-endian) byte order


String Directive    |               | Meaning
:------------------:|:--------------|:--------------------------------------------------
A         | String  | arbitrary binary string (space padded, count is width)
a         | String  | arbitrary binary string (null padded, count is width)
Z         | String  | same as ``a'', except that null is added with *
B         | String  | bit string (MSB first)
b         | String  | bit string (LSB first)
H         | String  | hex string (high nibble first)
h         | String  | hex string (low nibble first)
u         | String  | UU-encoded string
M         | String  | quoted printable, MIME encoding (see RFC2045)
m         | String  | base64 encoded string (see RFC 2045, count is width)
‌‌          |         | (if count is 0, no line feed are added, see RFC 4648)
P         | String  | pointer to a structure (fixed-length string)
p         | String  | pointer to a null-terminated string

Misc. Directive     |               | Meaning
:------------------:|:--------------|:--------------------------------------------------
@         |         | moves to absolute position
X         |         | back up a byte
x         |         | null byte

[Table Source](https://rubydoc.info/stdlib/core/1.9.3/Array:pack)

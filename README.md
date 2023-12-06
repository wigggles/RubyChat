# Ruby CLI-Chat Client/Server

Ensure you have Ruby installed.

This is a basic example of how a TCP server socket can be created for running a CLI chat service. It contains a server.rb and a client.rb Ruby script for running a command line interface chatting system. Client sessions have managed data set up as string byte blocks to provide and example of how to package an array of data for transmission.

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

https://ruby-doc.org/3.2.2/packed_data_rdoc.html

https://ruby-doc.org/stdlib-2.0.0/libdoc/socket/rdoc/Addrinfo.html

https://stackoverflow.com/questions/13270042/get-public-remote-ip-address

https://ruby-doc.org/stdlib-2.6.3/libdoc/open-uri/rdoc/OpenURI.html

https://ruby-doc.org/3.2.2/exts/socket/TCPSocket.html

https://www.rubyguides.com/2017/01/read-binary-data/


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
* Gosu UI
* Client/Server graceful shutdowns
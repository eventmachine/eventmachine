# Overview of this fork of EventMachine

This is a fork of [EventMachine](http://github.com/eventmachine/eventmachine).

If you are looking for a stable version, look there.

## Purpose of the fork

This version corrects some of the more annoying problems EventMachine
has in the area of IPv6 support.  I didn't try to do a full code
review and fix everything, but fixed just what I needed.

## Roadmap

I mostly changed references to `struct sockaddr` into `struct sockaddr_storage`.
(Folks, RFC 2533 has now been in force more than eleven years...)
As an exception, I changed the `From` member of `OutboundPage` to a
`sockaddr_in6`, as this needs appreciably less storage and causes less
copying to go on.

I also tried to use em.cpp's `name2address` in more places, so more
places are IPv6 aware.  This meant

- throwing out a bit of the rampant code duplication (this needs to continue)
- making `name2address` a static member of `EventMachine_t`.

I also changed the test for datagram sockets (which is in
`test_epoll.rb` of all places) to also test `::1` in addition to `127.0.0.1`.
(Unfortunately, the error handling of EventMachine datagrams is broken
enough that I couldn't make this fully resilient to random legacy systems.)

## Features

The result of these changes is that UDP datagrams can now be sent and
received over IPv6, and `get_peername` and `get_sockname` appear to work
in more cases.

The changes have been tested on Solaris 10 and OSX 10.6.4 only.
(They probably need a couple more `#ifdef`s for old versions of Cygwin.)

## License

The fixes I have made are too small to create any author's rights.

Just in case your jurisdiction is strange enough that the above does
not apply, I'm licensing the changes both under the license in
docs/LEGAL and the two-clause BSD license, q.v.

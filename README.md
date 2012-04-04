# About EventMachine-LE #

EventMachine-LE (Live Edition) is a branch of [EventMachine](http://github.com/eventmachine/eventmachine).

## What do you mean by "branch"? ##

Well, outside the narrower git circles, "fork" has all these negative
connotations, as in bad feelings after an argument, marriages
divorcing, nation states splitting after a civil war, people hating
each other.  This is not at all the point here, so let's call this
fork a "branch".

## Purpose of this branch ##

This branch incorporates interesting pull requests that are not yet
included in the mainline EventMachine repository.  The maintainers of
that version prefer to minimize change in order to keep the stability
with already existing EventMachine deployments, which provides an
impressive multi-platform base for IPv4 TCP servers (e.g., Web
servers) that don't need good UDP or IPv6 support.

This dedication to stability is helpful for production use, but can
also lead to ossification.  The present "Live Edition" or "Leading
Edge" branch has its focus on supporting a somewhat wider use,
including new Web servers or protocols beyond the HTTP Web.

To provide even more focus, this branch is currently applying its
energy towards Linux and Unix/BSD/OSX environments.  Java reactor and
pure Ruby reactor are for now removed in this branch, and
Windows/Cygwin support is untested.  This may very well change later,
once interesting pull requests come in.

EventMachine-LE draws from a number of dormant pull requests on the
mainline version of EventMachine.  New proposals will also directly
come to EventMachine-LE and will be included once they are tested.

This is not a "development branch" — we do use EventMachine-LE in production,
just beyond the focus of mainline EventMachine.

The intention is that EventMachine-LE is always a drop-in replacement
for EventMachine, just with additional (and fixed) functionality.


## Features and changes ##

The list of additions and improvements will grow over time. Currently
the following features/fixes have been applied in EventMachine-LE:

* Full IPv6 support for TCP and UDP, in both server and client mode ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* Added robustness to datagram sockets, which now can optionally not to get destroyed on the first error by setting `EM::Connection#send_error_handling=mode` ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* `EM::attach_server` added ([ramonmaruko](https://github.com/eventmachine/eventmachine/pull/271)).
* `EM::RestartableTimer` added ([adzap](https://github.com/eventmachine/eventmachine/pull/114)).
* `EM::get_max_timers` and `EM::set_max_timers` are removed (they still exist but do nothing). This solves the annoying "RuntimeError: max timers exceeded" exception.
* Support for Enumerable in `EM::Iterator` ([fl00r](https://github.com/eventmachine/eventmachine/pull/300)).
* Improvements to `EM::Protocols::LineProtocol` and have it autoload ([gaffneyc](https://github.com/eventmachine/eventmachine/pull/151)).
* `EM::Protocols::SmtpServer`: support multiple messages per one connection and login auth type ([bogdan](https://github.com/eventmachine/eventmachine/pull/288)).
* Reimplement `EM::Queue` to avoid shift/push performance problem ([grddev](https://github.com/eventmachine/eventmachine/pull/311)).
* Many code cleanups.


## Installation ##

The Current stable version is eventmachine-le-1.1.0 (published as Ruby Gem), installable via:
<pre>
gem install eventmachine-le
</pre>

If you want the beta version (not fully tested) install it by using `--pre` option:
<pre>
gem install eventmachine-le --pre
</pre>


## Usage ##

Using EventMachine-LE within your project just requires loading it as follows:
<pre>
# First load EventMachine-LE.
require "eventmachine-le"

# NOTE: It does not hurt to call "require 'eventmachine'" *later* (it has no effect at all).

# Then load any other Ruby Gem depending on EventMachine so it
# will use EventMachine-LE.
require "em-udns"
</pre>

By doing this, you will avoid conflicts with the main EventMachine Gem (if it's also installed).


## Authors ##

This branch is mantained by [Carsten Bormann](https://github.com/cabo) and [Iñaki Baz Castillo](https://github.com/ibc).

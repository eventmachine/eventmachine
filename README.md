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

This is not a "development branch" — we do intend to use
EventMachine-LE in production, just beyond the focus of mainline
EventMachine.

## Features and changes ##

The list of additions and improvements will grow over time. Currently
the following features/fixes have been applied in EventMachine-LE:

* Full IPv6 support for TCP and UDP, in both server and client mode ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* Added robustness to datagram sockets, which now can optionally not to get destroyed on the first error by setting `EM::Connection#send_error_handling=mode` ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* `EM::attach_server` added ([ramonmaruko](https://github.com/eventmachine/eventmachine/pull/271)).
* `EM::RestartableTimer` added ([adzap](https://github.com/eventmachine/eventmachine/pull/114)).
* `EM::get_max_timers` and `EM::set_max_timers` are removed (they still exist but do nothing). This solves the annoying "RuntimeError: max timers exceeded" exception.
* Improvements to `EM::Protocols::LineProtocol` and have it autoload ([gaffneyc](https://github.com/eventmachine/eventmachine/pull/151)).
* Many code cleanups.


## Installation ##

Install the Ruby Gem:
<pre>
gem install eventmachine-le
</pre>


## Usage ##

In order to use this branch in your project, make sure you load it as follows:
<pre>
# First load EventMachine-LE.
require "eventmachine-le"
# Later load any other Ruby Gem depending on EventMachine so they will use EventMachine-LE.
require "em-udns"
</pre>

By doing this, you will avoid conflicts with the main EventMachine Gem (if it's also installed).


## Authors ##

This branch is mantained by [Carsten Bormann](https://github.com/cabo) and [Iñaki Baz Castillo](https://github.com/ibc).

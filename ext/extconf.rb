# $Id$
#
#----------------------------------------------------------------------------
#
# Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
# Gmail: blackhedd
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU General Public License
# as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#---------------------------------------------------------------------------
#
# extconf.rb for Ruby/EventMachine
# We have to munge LDSHARED because this code needs a C++ link.
#

require 'mkmf'

flags = []

case RUBY_PLATFORM.split('-',2)[1]
when 'mswin32', 'mingw32', 'bccwin32'
  unless have_header('windows.h') and
      have_header('winsock.h') and
      have_library('kernel32') and
      have_library('rpcrt4') and
      have_library('gdi32')
    exit
  end

  flags << "-D OS_WIN32"
  flags << '-D BUILD_FOR_RUBY'
  flags << "-EHs"
  flags << "-GR"

  dir_config('ssl')
  if have_library('ssleay32') and
	  have_library('libeay32') and
	  have_header('openssl/ssl.h') and
	  have_header('openssl/err.h')
    flags << '-D WITH_SSL'
  else
    flags << '-D WITHOUT_SSL'
  end

when /solaris/
  unless have_library('pthread') and
	have_library('nsl') and
	have_library('socket')
	  exit
  end

  flags << '-D OS_UNIX'
  flags << '-D OS_SOLARIS8'
  flags << '-D BUILD_FOR_RUBY'

  dir_config('ssl')
  if have_library('ssl') and
	  have_library('crypto') and
	  have_header('openssl/ssl.h') and
	  have_header('openssl/err.h')
    flags << '-D WITH_SSL'
  else
    flags << '-D WITHOUT_SSL'
  end

  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"

  # Patch by Tim Pease, fixes SUNWspro compile problems.
  if CONFIG['CC'] == 'cc'
    $CFLAGS = CONFIG['CFLAGS'] = "-g -O2 -fPIC"
    CONFIG['CCDLFLAGS'] = "-fPIC"
  end

when /darwin/
  flags << '-DOS_UNIX'
  flags << '-DBUILD_FOR_RUBY'

  if have_header("sys/event.h") and have_header("sys/queue.h")
    flags << "-DHAVE_KQUEUE"
  end

  dir_config('ssl')
  if have_library('ssl') and
	  have_library('crypto') and
	  have_library('C') and
	  have_header('openssl/ssl.h') and
	  have_header('openssl/err.h')
    flags << '-DWITH_SSL'
  else
    flags << '-DWITHOUT_SSL'
  end
  # on Unix we need a g++ link, not gcc.
  # Ff line contributed by Daniel Harple.
  CONFIG['LDSHARED'] = "$(CXX) " + CONFIG['LDSHARED'].split[1..-1].join(' ')

when /linux/
  unless have_library('pthread')
	  exit
  end

  flags << '-DOS_UNIX'
  flags << '-DBUILD_FOR_RUBY'

  # Original epoll test is inadequate because 2.4 kernels have the header
  # but not the code.
  #flags << '-DHAVE_EPOLL' if have_header('sys/epoll.h')
  if have_header('sys/epoll.h')
	  File.open("hasEpollTest.c", "w") {|f|
		  f.puts "#include <sys/epoll.h>"
		  f.puts "int main() { epoll_create(1024); return 0;}"
	  }
	  (e = system( "gcc hasEpollTest.c -o hasEpollTest " )) and (e = $?.to_i)
	  `rm -f hasEpollTest.c hasEpollTest`
	  flags << '-DHAVE_EPOLL' if e == 0
  end

  if have_func('rb_thread_blocking_region') and have_macro('RB_UBF_DFL', 'ruby.h')
	  flags << "-DHAVE_TBR"
  end

  dir_config('ssl', "#{ENV['OPENSSL']}/include", ENV['OPENSSL'])
  # Check for libcrypto twice, before and after ssl. That's because on some platforms
  # and openssl versions, libssl will emit unresolved externals from crypto. It
  # would be cleaner to simply check crypto first, but that doesn't always work in 
  # Ruby. The order we check them doesn't seem to control the order in which they're
  # emitted into the link command. This is pretty weird, I have to admit.
  if have_library('crypto') and
	  have_library('ssl') and
	  have_library('crypto') and
	  have_header('openssl/ssl.h') and
	  have_header('openssl/err.h')
    flags << '-DWITH_SSL'
  else
    flags << '-DWITHOUT_SSL'
  end
  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"

  # Modify the mkmf constant LINK_SO so the generated shared object is stripped.
  # You might think modifying CONFIG['LINK_SO'] would be a better way to do this,
  # but it doesn't work because mkmf doesn't look at CONFIG['LINK_SO'] again after
  # it initializes.
  linkso = Object.send :remove_const, "LINK_SO"
  LINK_SO = linkso + "; strip $@"

else
  unless have_library('pthread')
	  exit
  end

  flags << '-DOS_UNIX'
  flags << '-DBUILD_FOR_RUBY'

  if have_header("sys/event.h") and have_header("sys/queue.h")
    flags << "-DHAVE_KQUEUE"
  end

  dir_config('ssl')
  if have_library('ssl') and
	  have_library('crypto') and
	  have_header('openssl/ssl.h') and
	  have_header('openssl/err.h')
    flags << '-DWITH_SSL'
  else
    flags << '-DWITHOUT_SSL'
  end
  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"

end

if $CPPFLAGS
  $CPPFLAGS += ' ' + flags.join(' ')
else
  $CFLAGS += ' ' + flags.join(' ')
end


create_makefile "rubyeventmachine"

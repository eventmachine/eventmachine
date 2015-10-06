require 'fileutils'
require 'mkmf'

def check_libs libs = [], fatal = false
  libs.all? { |lib| have_library(lib) || (abort("could not find library: #{lib}") if fatal) }
end

def check_heads heads = [], fatal = false
  heads.all? { |head| have_header(head) || (abort("could not find header: #{head}") if fatal)}
end

def add_define(name)
  $defs.push("-D#{name}")
end

##
# OpenSSL:

# override append_library, so it actually appends (instead of prepending)
# this fixes issues with linking ssl, since libcrypto depends on symbols in libssl
def append_library(libs, lib)
  libs + " " + format(LIBARG, lib)
end

def manual_ssl_config
  ssl_libs_heads_args = {
    :unix => [%w[ssl crypto], %w[openssl/ssl.h openssl/err.h]],
    :mswin => [%w[ssleay32 libeay32], %w[openssl/ssl.h openssl/err.h]],
  }

  dc_flags = ['ssl']
  dc_flags += ["#{ENV['OPENSSL']}/include", ENV['OPENSSL']] if /linux/ =~ RUBY_PLATFORM and ENV['OPENSSL']

  libs, heads = case RUBY_PLATFORM
  when /mswin|mingw|bccwin/ ; ssl_libs_heads_args[:mswin]
  else                        ssl_libs_heads_args[:unix]
  end
  dir_config(*dc_flags)
  check_libs(libs) and check_heads(heads)
end

# Eager check devs tools
have_devel? if respond_to?(:have_devel?)

if ENV['CROSS_COMPILING']
  openssl_version = ENV.fetch("OPENSSL_VERSION", "1.0.1i")
  openssl_dir = File.expand_path("~/.rake-compiler/builds/openssl-#{openssl_version}/")
  if File.exist?(openssl_dir)
    FileUtils.mkdir_p Dir.pwd+"/openssl/"
    FileUtils.cp Dir[openssl_dir+"/include/openssl/*.h"], Dir.pwd+"/openssl/", :verbose => true
    FileUtils.cp Dir[openssl_dir+"/lib*.a"], Dir.pwd, :verbose => true
    $INCFLAGS << " -I#{Dir.pwd}" # for the openssl headers
  else
    STDERR.puts
    STDERR.puts "**************************************************************************************"
    STDERR.puts "**** Cross-compiled OpenSSL not found"
    STDERR.puts "**** Run: hg clone http://bitbucket.org/ged/ruby-pg && cd ruby-pg && rake openssl_libs"
    STDERR.puts "**************************************************************************************"
    STDERR.puts
  end
end

# Try to use pkg_config first, fixes #73
if (!ENV['CROSS_COMPILING'] and pkg_config('openssl')) || manual_ssl_config
  add_define "WITH_SSL"
end

add_define 'BUILD_FOR_RUBY'
add_define 'HAVE_RBTRAP' if have_var('rb_trap_immediate', ['ruby.h', 'rubysig.h'])
add_define "HAVE_TBR" if have_func('rb_thread_blocking_region')# and have_macro('RUBY_UBF_IO', 'ruby.h')
add_define "HAVE_RB_THREAD_CALL_WITHOUT_GVL" if have_header('ruby/thread.h') && have_func('rb_thread_call_without_gvl', 'ruby/thread.h')
add_define "HAVE_INOTIFY" if inotify = have_func('inotify_init', 'sys/inotify.h')
add_define "HAVE_OLD_INOTIFY" if !inotify && have_macro('__NR_inotify_init', 'sys/syscall.h')
add_define 'HAVE_WRITEV' if have_func('writev', 'sys/uio.h')
add_define 'HAVE_RB_THREAD_FD_SELECT' if have_func('rb_thread_fd_select')
add_define 'HAVE_RB_FDSET_T' if have_type('rb_fdset_t', 'ruby/intern.h')
add_define 'HAVE_PIPE2' if have_func('pipe2', 'unistd.h')
add_define 'HAVE_ACCEPT4' if have_func('accept4', 'sys/socket.h')
add_define 'HAVE_SOCK_CLOEXEC' if have_const('SOCK_CLOEXEC', 'sys/socket.h')

have_func('rb_wait_for_single_fd')
have_func('rb_enable_interrupt')
have_func('rb_time_new')

# Minor platform details between *nix and Windows:

if RUBY_PLATFORM =~ /(mswin|mingw|bccwin)/
  GNU_CHAIN = ENV['CROSS_COMPILING'] || $1 == 'mingw'
  OS_WIN32 = true
  add_define "OS_WIN32"
else
  GNU_CHAIN = true
  OS_UNIX = true
  add_define 'OS_UNIX'

  add_define "HAVE_KQUEUE" if have_header("sys/event.h") and have_header("sys/queue.h")
end

# Adjust number of file descriptors (FD) on Windows

if RbConfig::CONFIG["host_os"] =~ /mingw/
  found = RbConfig::CONFIG.values_at("CFLAGS", "CPPFLAGS").
    any? { |v| v.include?("FD_SETSIZE") }

  add_define "FD_SETSIZE=32767" unless found
end

# Main platform invariances:

case RUBY_PLATFORM
when /mswin32/, /mingw32/, /bccwin32/
  check_heads(%w[windows.h winsock.h], true)
  check_libs(%w[kernel32 rpcrt4 gdi32], true)

  if GNU_CHAIN
    CONFIG['LDSHAREDXX'] = "$(CXX) -shared -static-libgcc -static-libstdc++"
  else
    $defs.push "-EHs"
    $defs.push "-GR"
  end

when /solaris/
  add_define 'OS_SOLARIS8'
  check_libs(%w[nsl socket], true)

  # If Ruby was compiled for 32-bits, then select() can only handle 1024 fds
  # There is an alternate function, select_large_fdset, that supports more.
  add_define 'HAVE_SELECT_LARGE_FDSET' if have_func('select_large_fdset', 'sys/select.h')

  if CONFIG['CC'] == 'cc' && (
     `cc -flags 2>&1` =~ /Sun/ || # detect SUNWspro compiler
     `cc -V 2>&1` =~ /Sun/        # detect Solaris Studio compiler
    )
    # SUN CHAIN
    add_define 'CC_SUNWspro'
    $preload = ["\nCXX = CC"] # hack a CXX= line into the makefile
    $CFLAGS = CONFIG['CFLAGS'] = "-KPIC"
    CONFIG['CCDLFLAGS'] = "-KPIC"
    CONFIG['LDSHARED'] = "$(CXX) -G -KPIC -lCstd"
    CONFIG['LDSHAREDXX'] = "$(CXX) -G -KPIC -lCstd"
  else
    # GNU CHAIN
    # on Unix we need a g++ link, not gcc.
    CONFIG['LDSHARED'] = "$(CXX) -shared"
  end

when /openbsd/
  # OpenBSD branch contributed by Guillaume Sellier.

  # on Unix we need a g++ link, not gcc. On OpenBSD, linking against libstdc++ have to be explicitly done for shared libs
  CONFIG['LDSHARED'] = "$(CXX) -shared -lstdc++ -fPIC"
  CONFIG['LDSHAREDXX'] = "$(CXX) -shared -lstdc++ -fPIC"

when /darwin/
  add_define 'OS_DARWIN'

  # on Unix we need a g++ link, not gcc.
  # Ff line contributed by Daniel Harple.
  CONFIG['LDSHARED'] = "$(CXX) " + CONFIG['LDSHARED'].split[1..-1].join(' ')

when /linux/
  add_define 'HAVE_EPOLL' if have_func('epoll_create', 'sys/epoll.h')

  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"

when /aix/
  CONFIG['LDSHARED'] = "$(CXX) -shared -Wl,-G -Wl,-brtl"

when /cygwin/
  # For rubies built with Cygwin, CXX may be set to CC, which is just
  # a wrapper for gcc.
  # This will compile, but it will not link to the C++ std library.
  # Explicitly set CXX to use g++.
  CONFIG['CXX'] = "g++"
  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"

else
  # on Unix we need a g++ link, not gcc.
  CONFIG['LDSHARED'] = "$(CXX) -shared"
end

# This is our wishlist. We use whichever flags work on the host.
# In the future, add -Werror to make sure all warnings are resolved.
# deprecated-declarations are used in OS X OpenSSL
# ignored-qualifiers are used by the Bindings (would-be void *)
# unused-result because GCC 4.6 no longer silences (void) ignore_this(function)
# address because on Windows, rb_fd_select checks if &fds is non-NULL, which it cannot be
%w(
  -Wall
  -Wextra
  -Wno-deprecated-declarations
  -Wno-ignored-qualifiers
  -Wno-unused-result
  -Wno-address
).select do |flag|
  try_link('int main() {return 0;}', flag)
end.each do |flag|
  $CFLAGS << ' ' << flag
  $CPPFLAGS << ' ' << flag
end
puts "CFLAGS=#{$CFLAGS}"
puts "CPPFLAGS=#{$CPPFLAGS}"

# Platform-specific time functions
if have_func('clock_gettime')
  # clock_gettime is POSIX, but the monotonic clocks are not
  have_const('CLOCK_MONOTONIC_RAW', 'time.h') # Linux
  have_const('CLOCK_MONOTONIC', 'time.h') # Linux, Solaris, BSDs
else
  have_func('gethrtime') # Older Solaris and HP-UX
end

# solaris c++ compiler doesn't have make_pair()
TRY_LINK.sub!('$(CC)', '$(CXX)')
add_define 'HAVE_MAKE_PAIR' if try_link(<<SRC, '-lstdc++')
  #include <utility>
  using namespace std;
  int main(){ pair<const int,int> tuple = make_pair(1,2); }
SRC
TRY_LINK.sub!('$(CXX)', '$(CC)')

create_makefile "rubyeventmachine"

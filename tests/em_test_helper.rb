require 'eventmachine'
require 'test/unit'

Test::Unit::TestCase.class_eval do
  def setup_timeout(timeout = 0.5)
    EM.schedule {
      EM.add_timer(timeout) {
        raise "timeout" 
      }
    }
  end

  # http://blog.emptyway.com/2009/11/03/proper-way-to-detect-windows-platform-in-ruby/
  def self.windows?
    require 'rbconfig'
    Config::CONFIG['host_os'] =~ /mswin|mingw/
  end

  # http://stackoverflow.com/questions/1342535/how-can-i-tell-if-im-running-from-jruby-vs-ruby/1685970#1685970
  def self.jruby?
    defined? JRUBY_VERSION
  end
end

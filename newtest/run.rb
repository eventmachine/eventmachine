DIR = File.expand_path(File.dirname(__FILE__)) 

begin
  require 'bacon'
rescue LoadError
  require 'rubygems'
  require 'bacon'
end
require 'eventmachine'
Bacon.summary_at_exit

Dir.glob(DIR+"/tests/*.rb").each {|f| require f}

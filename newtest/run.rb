DIR = File.expand_path(File.dirname(__FILE__)) 

require 'bacon'
require 'eventmachine'
Bacon.summary_at_exit

Dir.glob(DIR+"/tests/*.rb").each {|f| require f}

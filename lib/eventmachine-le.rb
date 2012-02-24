# This file allows usage of
#
#   require "eventmachine-le"
#
# and ensures that the eventmachine.rb and em/xxx.rb loaded files are those
# within eventmachine-le Gem rather than the official eventmachine Gem files
# (if installed).

gem 'eventmachine-le'
require 'eventmachine'

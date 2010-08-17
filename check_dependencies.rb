#!/usr/bin/env ruby
require 'rubygems'

puts "=== Checking that your system has the required packages and gems installed..."

# Check that bundler is installed
begin
  require 'bundler'
  puts "===== Bundler is installed."
rescue LoadError
  puts "==!!! Please install gem 'bundler'   ====> $ sudo gem install bundler"
end

# Check that mplayer is installed
apt_search = `aptitude search mplayer`
if apt_search[/^(i [A ] mplayer)/, 1]
  puts "===== mplayer is installed."
else
  puts "==!!! Please install package 'mplayer'   ====> $ sudo apt-get install mplayer"
end


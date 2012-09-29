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

def has_mplayer
  ENV['PATH'].split(':').each {|f| 
    return true if File.exists?("#{f}/mplayer")
  }
  return false
end
if has_mplayer
  puts "===== mplayer is installed."
else
  puts "==!!! Please install package 'mplayer'   ====> Debian/Ubuntu: $ sudo apt-get install mplayer"
  puts "==!!!                                    ====> Arch: $ sudo pacman -S mplayer "

end


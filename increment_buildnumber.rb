#!/usr/bin/env macruby

require 'HotCocoa'

buildnumber = File.new("buildnumber", "r").gets.to_i
buildnumber += 1
File.new("buildnumber", "w+").puts(buildnumber.to_s)

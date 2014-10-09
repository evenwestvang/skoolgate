#! /usr/bin/env ruby

require 'amatch'
require 'getoptlong'

def usage(msg, options)
  puts msg, "Usage: #{File.basename($0)} [OPTIONS] PATTERN [FILE ...]", ""
  options.each do |o|
    puts "  " + o[1] + ", " + o[0] + " " +
      (o[2] == GetoptLong::REQUIRED_ARGUMENT ? 'ARGUMENT' : '')
  end
  puts "\nReport bugs to <flori@ping.de>."
  exit 0
end

class Amatch::Levenshtein
  def search_relative(strings)
    search(strings).to_f / pattern.size
  end
end

$distance = 1
$mode = :search
begin
  parser = GetoptLong.new
  options = [
    [ '--distance',   '-d',  GetoptLong::REQUIRED_ARGUMENT ],
    [ '--relative',   '-r',  GetoptLong::NO_ARGUMENT ],
    [ '--verbose',    '-v',  GetoptLong::NO_ARGUMENT ],
    [ '--help',       '-h',  GetoptLong::NO_ARGUMENT ],
  ]
  parser.set_options(*options)
  parser.each_option do |name, arg|
    name = name.sub(/^--/, '')
    case name
    when 'distance'
      $distance = arg.to_f
    when 'relative'
      $mode = :search_relative
    when 'verbose'
      $verbose = 1
    when 'help'
      usage('You\'ve asked for it!', options)
    end
  end
rescue
  exit 1
end
pattern = ARGV.shift or usage('Pattern needed!', options)

matcher = Amatch::Levenshtein.new(pattern)
size = 0
start = Time.new
if ARGV.size > 0 then
  ARGV.each do |filename|
    File.stat(filename).file? or next
    size += File.size(filename)
    begin
      File.open(filename, 'r').each_line do |line|
        if matcher.__send__($mode, line) <= $distance
          puts "#{filename}:#{line}"
        end
      end
    rescue
      STDERR.puts "Failure at #{filename}: #{$!} => Skipping!"
    end
  end
else
  STDIN.each_line do |line|
    size += line.size
    if matcher.__send__($mode, line) <= $distance
      puts line
    end
  end
end
time = Time.new - start
$verbose and STDERR.printf "%.3f secs running, scanned %.3f KB/s.\n",
  time, size / time / 1024
exit 0

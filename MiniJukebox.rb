#!/usr/bin/ruby


# = Libraries
require 'hpricot'
require 'open-uri'
require 'date'
require 'optparse'

# Needs libcurl
# Needs mplayer


# = MiniJukebox is a very small and simple stream player with caching functionality
class MiniJukebox # {{{

  # = Initialzie constructor for the MiniJukebox class
  def initialize options # {{{
    @options = options
  end # of def initialize }}}

  # = Streams function will download streams or reload cache of music streams from shoutcast
  # Uses /tmp/ caching, which will keep the list for 1 day and download a new one
  def streams file = "/tmp/minijukebox-cache" # {{{
      if( @options[:usecache] )
          puts "o Using already cached playlists" if @options[:verbose]
          if( File.exists?( file ) ) 
              File.open( file ) { |f| @list = Marshal.load( f ) }                                   # load object from cache
          else  # file doesn't exist, create and cache
              puts "o Cache is empty need to cache streams from Website" if @options[:verbose]
              @list = getStreams!
              File.open( file, "w+" ) { |f| Marshal.dump( @list, f ) }
          end
      else
          if( @options[:recache] )
              puts "o Recache option given, performing recache *now*" if @options[:verbose]
              @list = getStreams!
              File.open( file, "w+" ) { |f| Marshal.dump( @list, f ) }
          else
              if( File.exists?( file ) ) 
                  # check time and maybe cache it because to old
                  if( Date.parse( File.stat( file ).mtime.to_s ).to_s == Date.jd(DateTime.now.jd).to_s )    # we cached it today
                      File.open( file ) { |f| @list = Marshal.load( f ) }                                   # load object from cache
                  else  # file is to old, get new and cache
                      puts "o Cache is older than 1 day, need to recache *now*" if @options[:verbose]
                      @list = getStreams!
                      File.open( file, "w+" ) { |f| Marshal.dump( @list, f ) }
                  end
              else  # file doesn't exist, create and cache
                  puts "o Cache is empty need to cache streams from Website" if @options[:verbose]
                  @list = getStreams!
                  File.open( file, "w+" ) { |f| Marshal.dump( @list, f ) }
              end
          end
      end

      @list
  end # of def streams }}}


  # = GetStreams! function will download webcontent, parse it and return a list of accessable streams in order of ranking from shoutcast
  def getStreams! baseURL = "http://www.shoutcast.com/?numresult=20" # {{{
      choices = Array.new                                                                                               # we store our grabbed results here
      puts "Caching..."

      @ids = []
      Hpricot( open( "http://www.shoutcast.com/?numresult=20" )).search( '//div[@class="stationcol"]/a' ).each do |o|
        if( o.attributes['class'] =~ %r{playbutton[0-9]*}i )

          choices.push( [ o.attributes['name'], getStreamURLFromPLSFile!( o.attributes['href'].to_s.split("=").last ) ] )
        end
      end

      print "\n"

      choices
  end # of def getStreams! }}}

  # = StreamSpeed function will use curl to measure the speed of the given stream url
  # @param time Testtime per stream
  # @returns Bytes (speed), as float
  # @warn Needs curl installed
  # FIXME: threads
  def streamSpeed url, time # {{{
    begin
      speedInByte = `curl -m#{time} --connect-timeout 5 -s -o /dev/null -w '%{speed_download}' #{url}`.to_f
    rescue
      raise Exception, "Needs libcurl (curl) installed."
    end
  end # of def streamSpeed }}}

  # = PrintMenu! function does print only a simple ASCII based menu with choices of <NUM>
  def printMenu! choices = getStreams! # {{{
      print "Please choose which music to play...\n\n" 
      if( @options[:time] )
          choices.each_with_index { |l, i| printf("%2i | Speed: %5.2f kB/s | %s\n", i, streamSpeed( l[1].first.to_s, 1)/1000.0, l[0].to_s) }
      else
          choices.each_with_index { |l, i| puts i.to_s+' |'+' '*4+l[0].to_s }
      end
      print "\nYour choice : "
      choices[ gets.chomp!.to_i ][1]
  end # of def printMenu! }}}

  # = GetStreamURLFromPLSFile! extracts the stream url from the downloaded pls files
  def getStreamURLFromPLSFile! plsID = nil, plsFileURL = "http://yp.shoutcast.com/sbin/tunein-station.pls?id=" # {{{
      raise ArgumentError, "Need a valid PLS ID" if plsID.nil?
      streamURL = Array.new
      Hpricot( open( plsFileURL + plsID.to_s ) ).to_s.each do |l| 
          streamURL << URI.extract(l,'http').to_s if l =~ %r{File}i
      end
      puts "  - #{plsFileURL+plsID.to_s}"
      streamURL
  end # of def getStreamURLFromPLSFile! }}}

  # = Play! function uses e.g. mplayer to play the given stream
  def play! streamURLs = printMenu!( streams ), playerProgram = "mplayer" # {{{
      streamURLs.each { |url| exec "#{playerProgram} #{url}" }
  end # of def play! }}}

end # of class MiniJukebox }}}


# Direct invocation
if __FILE__ == $0 # {{{

  @options = {}
  OptionParser.new do |opts|
      opts.banner = "Usage: minijukebox [options]"

      opts.on("-o", "--usecache", "Use the already cached Playlist") do |o|
          @options[:usecache] = o
      end

      opts.on("-r", "--recache", "Recache the Playlist *now*") do |r|
          @options[:recache] = r
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
      end

      opts.on("-t", "--time", "Benchmark all streams") do |t|
          @options[:time] = t
      end
  end.parse!

  m = MiniJukebox.new( @options )
  m.play!

end # of if __FILE__ == $0 # }}}

# EOF

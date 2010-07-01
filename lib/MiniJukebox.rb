#!/usr/bin/ruby
#

# = Standard Libraries
require 'optparse'

class MiniJukebox # {{{


end # of class MiniJukebox }}}


# = Direct invocation
if __FILE__ == $0

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: MiniJukebox.rb [options]"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose]   = v
    end

  end.parse!

  mini_jukebox = MiniJukebox.new( options )

end # of if __FILE__ == $0

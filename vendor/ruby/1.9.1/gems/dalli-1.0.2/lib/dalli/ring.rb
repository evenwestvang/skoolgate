require 'digest/sha1'
require 'zlib'

module Dalli
  class Ring
    POINTS_PER_SERVER = 160 # this is the default in libmemcached
    
    attr_accessor :servers, :continuum
    
    def initialize(servers, options)
      @servers = servers
      @continuum = nil
      if servers.size > 1
        total_weight = servers.inject(0) { |memo, srv| memo + srv.weight }
        continuum = []
        servers.each do |server|
          entry_count_for(server, servers.size, total_weight).times do |idx|
            hash = Digest::SHA1.hexdigest("#{server.hostname}:#{server.port}:#{idx}")
            value = Integer("0x#{hash[0..7]}")
            continuum << Dalli::Ring::Entry.new(value, server)
          end
        end
        @continuum = continuum.sort { |a, b| a.value <=> b.value }
      end

      threadsafe! unless options[:threadsafe] == false
      @failover = options[:failover] != false
    end
    
    def server_for_key(key)
      if @continuum
        hkey = hash_for(key)
        20.times do |try|
          entryidx = self.class.binary_search(@continuum, hkey)
          server = @continuum[entryidx].server
          return server if server.alive?
          break unless @failover
          hkey = hash_for("#{try}#{key}")
        end
      else
        server = @servers.first
        return server if server && server.alive?
      end

      raise Dalli::RingError, "No server available"
    end
    
    def lock
      @servers.each { |s| s.lock! }
      begin
        return yield
      ensure
        @servers.each { |s| s.unlock! }
      end
    end
    
    private

    def threadsafe!
      @servers.each do |s|
        s.extend(Dalli::Threadsafe)
      end
    end

    def hash_for(key)
      Zlib.crc32(key)
    end

    def entry_count_for(server, total_servers, total_weight)
      ((total_servers * POINTS_PER_SERVER * server.weight) / Float(total_weight)).floor
    end

    # Find the closest index in the Ring with value <= the given value
    def self.binary_search(ary, value)
      upper = ary.size - 1
      lower = 0
      idx = 0

      while (lower <= upper) do
        idx = (lower + upper) / 2
        comp = ary[idx].value <=> value

        if comp == 0
          return idx
        elsif comp > 0
          upper = idx - 1
        else
          lower = idx + 1
        end
      end
      return upper
    end

    class Entry
      attr_reader :value
      attr_reader :server

      def initialize(val, srv)
        @value = val
        @server = srv
      end
    end

  end
end

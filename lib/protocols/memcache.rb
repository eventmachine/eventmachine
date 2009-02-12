module EventMachine
  module Protocols
    # Implements the Memcache protocol (http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt).
    #
    # == Usage example
    #
    #   EM.run{
    #     cache = EM::P::Memcache.connect 'localhost', 10140
    #
    #     cache.set :a, 'hello'
    #     cache.set :b, 'hi'
    #     cache.set :c, 'how are you?'
    #     cache.set :d, ''
    #
    #     cache.set :e, 'blah' do
    #       puts 'stored e=blah'
    #     end
    #
    #     cache.get(:a){ |v| p(v) }
    #     cache.get_hash(:a, :b, :c, :d){ |v| p(v) }
    #     cache.get(:a,:b,:c,:d){ |a,b,c,d| p([a,b,c,d]) }
    #
    #     cache.get(:a,:z,:b,:y){ |a,z,b,y| p([a,z,b,y]) }
    #     cache.get(:missing){ |m| p(m) }
    #   }
    #
    module Memcache
      include EM::Protocols::LineText2
      include EM::Deferrable

      Cstored = 'STORED'.freeze
      Cend    = 'END'.freeze

      ##
      # commands

      def get *keys
        callback{
          keys = keys.map{|k| k.to_s.gsub(/\s/,'_') }
          send_data "get #{keys.join(' ')}\r\n"
          @get_cbs << proc{ |values|
            yield *keys.map{ |k| values[k] }
          }
        }
      end

      def set key, val, exptime = 0, &cb
        callback{
          send_cmd 'set', key, 0, exptime, val.respond_to?(:bytesize) ? val.bytesize : val.size, block_given?
          send_data "#{val}\r\n"
          @set_cbs << cb if cb
        }
      end

      def get_hash *keys
        get *keys do |*values|
          yield keys.inject({}){ |hash, k| hash.update k => values[keys.index(k)] }
        end
      end

      ##
      # em hooks

      def self.connect host = 'localhost', port = 11211
        EM.connect host, port, self, host, port
      end

      def initialize host, port = 11211
        @host, @port = host, port
      end

      def connection_completed
        set_delimiter "\r\n"
        set_line_mode
        @connected = true
        @values = {}
        @get_cbs = []
        @set_cbs = []
        succeed
      end

      def receive_line line
        case line
        when /^VALUE\s+(.+?)\s+(\d+)\s+(\d+)/ # VALUE <key> <flags> <bytes>
          bytes = Integer($3)
          if bytes > 0
            @cur_key = $1
            set_text_mode bytes
          else
            @values[$1] = ''
          end

        when Cstored
          # set succeeded
          if cb = @set_cbs.shift
            cb.call(true)
          end

        when Cend
          if cb = @get_cbs.shift
            cb.call(@values)
          end
          @values = {}
        end
      end

      def receive_binary_data data
        @values[@cur_key] = data
      end

      def unbind
        if @connected
          EM.add_timer(1){
            reconnect @host, @port
          }
          @connected = false
          @deferred_status = nil
        else
          raise 'Unable to connect to memcached server'
        end
      end

      private

      def send_cmd cmd, key, flags = 0, exptime = 0, bytes = 0, noreply = false
        send_data "#{cmd} #{key} #{flags} #{exptime} #{bytes}#{noreply ? ' noreply' : ''}\r\n"
      end
    end
  end
end
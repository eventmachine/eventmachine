module EventMachine
  # Utility class that is useful for file monitoring. Supported events are
  #
  # * File is modified
  # * File is deleted
  # * File is moved
  #
  # @note On Mac OS X, file watching only works when kqueue is enabled
  #
  # @see EventMachine.watch_file
  class FileWatch < Connection
    # @private
    Cmodified = "\0modified".freeze
    # @private
    Cdeleted = "\0deleted".freeze
    # @private
    Cmoved = "\0moved".freeze


    # @private
    def receive_data(data)
      case data
      when Cmodified
        _file_modified
      when Cdeleted
        _file_deleted
      when Cmoved
        _file_moved
      else
        @arg = data
      end
    end

    # :stopdoc:
    module CallWithArg # :nodoc: all
      def _file_modified
        arg, @arg = @arg, nil
        file_modified(arg)
      end
      def _file_deleted
        arg, @arg = @arg, nil
        file_deleted(arg)
      end
      def _file_moved
        arg, @arg = @arg, nil
        file_moved(arg)
      end
    end

    module CallWithoutArg # :nodoc: all
      def _file_modified
        file_modified
      end
      def _file_deleted
        file_deleted
      end
      def _file_moved
        file_moved
      end
    end

    %w{_file_modified _file_deleted _file_moved}.each do |method|
      define_method(method) do
        if method(method[1..-1]).arity == 0
          extend CallWithoutArg
        else
          extend CallWithArg
        end
        send(method)
      end
    end
    # :startdoc:

    # Returns the path that is being monitored.
    #
    # @note Current implementation does not pick up on the new filename after a rename occurs.
    #
    # @return [String]
    # @see EventMachine.watch_file
    def path
      @path
    end

    # Will be called when the file is modified. Supposed to be redefined by subclasses.
    #
    # On Linux this method could be called with filename argument when directory is watched.
    #
    # @abstract
    def file_modified(arg = nil)
    end

    # Will be called when the file is deleted. Supposed to be redefined by subclasses.
    # When the file is deleted, stop_watching will be called after this to make sure everything is
    # cleaned up correctly.
    #
    # On Linux this method could be called with filename argument when directory is watched.
    #
    # @note On Linux (with {http://en.wikipedia.org/wiki/Inotify inotify}), this method will not be called until *all* open file descriptors to
    #       the file have been closed.
    #
    # @abstract
    def file_deleted(arg = nil)
    end

    # Will be called when the file is moved or renamed. Supposed to be redefined by subclasses.
    #
    # On Linux this method could be called with filename argument when directory is watched.
    #
    # @abstract
    def file_moved(arg = nil)
    end

    # Discontinue monitoring of the file.
    #
    # This involves cleaning up the underlying monitoring details with kqueue/inotify, and in turn firing {EventMachine::Connection#unbind}.
    # This will be called automatically when a file is deleted. User code may call it as well.
    def stop_watching
      EventMachine::unwatch_filename(@signature)
    end # stop_watching
  end # FileWatch
end # EventMachine

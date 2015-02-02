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
    CInotifyEvents = [
      [1, [:modify]],
      [2, [:create, :appear]],
      [4, [:delete, :disappear]],
      [8, [:moved_from, :disappear]],
      [16, [:moved_to, :appear]],
      [32, [:is_dir]]
    ]

    # @private
    def receive_data(data)
      case data
      when Cmodified
        _file_modified
      when Cdeleted
        file_deleted
      when Cmoved
        file_moved
      else
        @arg = data
      end
    end

    # :stopdoc:
    def _file_modified
      @_file_modified_arity ||= method(:file_modified).arity
      if @_file_modified_arity == 0
        file_modified
      elsif @arg
        arg, @arg = @arg, nil
        event, file = arg[0].ord, arg[1..-1]
        events = [file]
        CInotifyEvents.each{|k, v|
          events |= v unless event & k == 0
        }
        file_modified(events)
      else
        file_modified(nil)
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

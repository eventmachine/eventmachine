module EventMachine

  # This is subclassed from EventMachine::Connection for use with the file monitoring API. Read the
  # documentation on the instance methods of this class, and for a full explanation see EventMachine.watch.
  class FileWatcher < Connection

    def receive_data(data) #:nodoc:
      case data
      when "modified"
        file_modified
      when "deleted"
        file_deleted
        stop_watching
      when "moved"
        file_moved
      end
    end

    # Returns the path that EventMachine::watch was originally called with. The current implementation
    # does not pick up on the new filename after a rename occurs.
    def path
      @path
    end

    # Should be redefined with the user's custom callback that will be fired when the file is modified.
    def file_modified
    end

    # Should be redefined with the user's custom callback that will be fired when the file is deleted.
    # When the file is deleted, stop_watching will be called after this to make sure everything is
    # cleaned up correctly.
    #
    # Note that on linux (with inotify), file_deleted will not be called until all open file descriptors to
    # the file have been closed.
    def file_deleted
    end

    # Should be redefined with the user's custom callback that will be fired when the file is moved or renamed.
    def file_moved
    end

    # Discontinue monitoring of the file.
    # This involves cleaning up the underlying monitoring details with kqueue/inotify, and in turn firing unbind.
    # This will be called automatically when a file is deleted. User code may call it as well.
    def stop_watching
      EventMachine::unwatch_file(@signature)
    end

  end

end
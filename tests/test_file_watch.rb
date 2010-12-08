require 'em_test_helper'
require 'tempfile'

class TestFileWatch < Test::Unit::TestCase
  if windows?
    def test_watch_file_raises_unsupported_error
      assert_raises(EM::Unsupported) do
        EM.run do
          file = Tempfile.new("fake_file")
          EM.watch_file(file.path)
        end
      end
    end
  else
    module FileWatcher
      def file_modified
        $modified = true
      end
      def file_deleted
        $deleted = true
      end
      def unbind
        $unbind = true
        EM.stop
      end
    end

    def setup
      EM.kqueue = true if EM.kqueue?
    end

    def teardown
      EM.kqueue = false if EM.kqueue?
    end

    def test_events
      EM.run{
        file = Tempfile.new('em-watch')
        $tmp_path = file.path

        # watch it
        watch = EM.watch_file(file.path, FileWatcher)
        $path = watch.path

        # modify it
        File.open(file.path, 'w'){ |f| f.puts 'hi' }

        # delete it
        EM.add_timer(0.01){ file.close; file.delete }
      }

      assert_equal($path, $tmp_path)
      assert($modified)
      assert($deleted)
      assert($unbind)
    end
  end
end

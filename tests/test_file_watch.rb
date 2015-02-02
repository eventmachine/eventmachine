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
  elsif EM.respond_to? :watch_filename
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

    module DirWatcherINotify
      def file_modified(file = nil)
        $modified << file
      end
      def unbind
        $unbind = true
        EM.stop
      end
    end

    def setup
      $modified = []
      $deleted = nil
      $unbind = nil
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

    if linux?
      def test_directory
        path = File.expand_path('../test_watch_dir', __FILE__)
        EM.run {
          Dir.mkdir(path)

          watch = EM.watch_file(path, DirWatcherINotify)

          file = File.join(path, 'test_file')
          file1 = File.join(path, 'test_file1')
          dir = File.join(path, 'test_dir')
          File.open(file, 'w') do end

          EM.add_timer(0.01){ 
            File.open(file, 'w') do end
            File.rename(file, file1)
            Dir.mkdir(dir)
            EM.add_timer(0.01){
              File.unlink(file1)
              Dir.unlink(dir)
              EM.add_timer(0.01) {
                Dir.rmdir(path)
              }
            }
          }
        }
        expected = [
          ['test_file', :create, :appear],
          ['test_file', :modify],
          ['test_file', :moved_from, :disappear],
          ['test_file1', :moved_to, :appear],
          ['test_dir', :create, :appear, :is_dir],
          ['test_file1', :delete, :disappear],
          ['test_dir', :delete, :disappear, :is_dir]
          ]
        assert_equal(expected, $modified)
      rescue
        Dir[path+'/*'].each{|f|
          if File.directory?(f)
            Dir.unlink(f)
          else
            File.unlink(f)
          end
        }
        Dir.rmdir(path)
        raise
      end
    end
  else
    warn "EM.watch_file not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_watch_file_unsupported
      assert true
    end
  end
end

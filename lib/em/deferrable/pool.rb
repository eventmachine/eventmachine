# = EM::Deferrable::Pool
#
# A simple async resource pool based on a resource and work queue. Resources
# are enqueued and work waits for resources to become available.
#
# Example:
#
#    EM.run do
#      pool  = EM::Deferrable::Pool.new
#      spawn = lambda { pool.add EM::HttpRequest.new('http://example.org') }
#      10.times { spawn[] }
#      done, scheduled = 0, 0
#    
#      check = lambda do
#        done += 1
#        if done >= scheduled
#          EM.stop
#        end
#      end
#    
#      pool.on_error { |conn| spawn[] }
#    
#      100.times do
#        pool.perform do |conn|
#          req = conn.get :path => '/', :keepalive => true
#    
#          req.callback do
#            p [:success, conn.object_id, i, req.response.size]
#            check[]
#          end
#    
#          req.errback { check[] }
#    
#          req
#        end
#      end
#    end
#
class EM::Deferrable::Pool
  def initialize
    @resources = EM::Queue.new
    @removed = []
    @on_error = nil
  end

  def add resource
    @resources.push resource
  end
  alias requeue add

  def remove resource
    @removed << resource
  end

  def on_error *a, &b
    @on_error = EM::Callback(*a, &b)
  end

  def perform(*a, &b)
    work = EM::Callback(*a, &b)

    @resources.pop do |resource|
      if removed? resource
        @removed.delete resource
        reschedule work
      else
        process work, resource
      end
    end
  end
  alias reschedule perform

  def process work, resource
    deferrable = work.call resource
    if deferrable.kind_of?(EM::Deferrable)
      completion deferrable, resource
    else
      raise ArgumentError, "deferrable expected from work"
    end
  end

  def completion deferrable, resource
    deferrable.callback { requeue resource }
    deferrable.errback  { failure resource }
  end

  def failure resource
    if @on_error
      @on_error.call resource
    else
      requeue resource
    end
  end

  def removed? resource
    @removed.include? resource
  end
end
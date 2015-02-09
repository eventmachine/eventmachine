/*****************************************************************************

$Id$

File:     em.h
Date:     06Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/

#ifndef __EventMachine__H_
#define __EventMachine__H_

#ifdef BUILD_FOR_RUBY
  #include <ruby.h>
  #define EmSelect rb_thread_fd_select

  #ifdef HAVE_RB_THREAD_CALL_WITHOUT_GVL
   #include <ruby/thread.h>
  #endif

  #ifdef HAVE_RB_WAIT_FOR_SINGLE_FD
    #include <ruby/io.h>
  #endif

  #if defined(HAVE_RBTRAP)
    #include <rubysig.h>
  #elif defined(HAVE_RB_ENABLE_INTERRUPT)
    extern "C" {
      void rb_enable_interrupt(void);
      void rb_disable_interrupt(void);
    }

    #define TRAP_BEG rb_enable_interrupt()
    #define TRAP_END do { rb_disable_interrupt(); rb_thread_check_ints(); } while(0)
  #else
    #define TRAP_BEG
    #define TRAP_END
  #endif

  // 1.9.0 compat
  #ifndef RUBY_UBF_IO
    #define RUBY_UBF_IO RB_UBF_DFL
  #endif
  #ifndef RSTRING_PTR
    #define RSTRING_PTR(str) RSTRING(str)->ptr
  #endif
  #ifndef RSTRING_LEN
    #define RSTRING_LEN(str) RSTRING(str)->len
  #endif
  #ifndef RSTRING_LENINT
    #define RSTRING_LENINT(str) RSTRING_LEN(str)
  #endif
#else
  #define EmSelect rb_fd_select
#endif

#ifndef rb_fd_max
#define fd_check(n) (((n) < FD_SETSIZE) ? 1 : 0*fprintf(stderr, "fd %d too large for select\n", (n)))
// These definitions are cribbed from include/ruby/intern.h in Ruby 1.9.3,
// with this change: any macros that read or write the nth element of an
// fdset first call fd_check to make sure n is in bounds.
typedef fd_set rb_fdset_t;
#define rb_fd_zero(f) FD_ZERO(f)
#define rb_fd_set(n, f) do { if (fd_check(n)) FD_SET((n), (f)); } while(0)
#define rb_fd_clr(n, f) do { if (fd_check(n)) FD_CLR((n), (f)); } while(0)
#define rb_fd_isset(n, f) (fd_check(n) ? FD_ISSET((n), (f)) : 0)
#define rb_fd_copy(d, s, n) (*(d) = *(s))
#define rb_fd_dup(d, s) (*(d) = *(s))
#define rb_fd_resize(n, f)  ((void)(f))
#define rb_fd_ptr(f)  (f)
#define rb_fd_init(f) FD_ZERO(f)
#define rb_fd_init_copy(d, s) (*(d) = *(s))
#define rb_fd_term(f) ((void)(f))
#define rb_fd_max(f)  FD_SETSIZE
#define rb_fd_select(n, rfds, wfds, efds, timeout)  \
  select(fd_check((n)-1) ? (n) : FD_SETSIZE, (rfds), (wfds), (efds), (timeout))
#define rb_thread_fd_select(n, rfds, wfds, efds, timeout)  \
  rb_thread_select(fd_check((n)-1) ? (n) : FD_SETSIZE, (rfds), (wfds), (efds), (timeout))
#endif

class EventableDescriptor;
class InotifyDescriptor;


/********************
class EventMachine_t
********************/

class EventMachine_t
{
	public:
		static int GetMaxTimerCount();
		static void SetMaxTimerCount (int);
		
		static int GetSimultaneousAcceptCount();
		static void SetSimultaneousAcceptCount (int);

	public:
		EventMachine_t (EMCallback);
		virtual ~EventMachine_t();

		int  Run();
		void ScheduleHalt();
		void SignalLoopBreaker();
		const unsigned long InstallOneshotTimer (int);
		const unsigned long ConnectToServer (const char *, int, const char *, int);
		const unsigned long ConnectToUnixServer (const char *);

		const unsigned long CreateTcpServer (const char *, int);
		const unsigned long OpenDatagramSocket (const char *, int);
		const unsigned long CreateUnixDomainServer (const char*);
		const unsigned long AttachSD (int);
		const unsigned long OpenKeyboard();
		//const char *Popen (const char*, const char*);
		const unsigned long Socketpair (char* const*);

		void Add (EventableDescriptor*);
		void Modify (EventableDescriptor*);
		void Deregister (EventableDescriptor*);

		const unsigned long AttachFD (int, bool);
		int DetachFD (EventableDescriptor*);

		void ArmKqueueWriter (EventableDescriptor*);
		void ArmKqueueReader (EventableDescriptor*);

		void SetTimerQuantum (int);
		static void SetuidString (const char*);
		static int SetRlimitNofile (int);

		pid_t SubprocessPid;
		int SubprocessExitStatus;

		int GetConnectionCount();
		float GetHeartbeatInterval();
		int SetHeartbeatInterval(float);

		const unsigned long WatchFile (const char*);
		void UnwatchFile (int);
		void UnwatchFile (const unsigned long);

		#ifdef HAVE_KQUEUE
		void _HandleKqueueFileEvent (struct kevent*);
		void _RegisterKqueueFileEvent(int);
		#endif

		const unsigned long WatchPid (int);
		void UnwatchPid (int);
		void UnwatchPid (const unsigned long);

		#ifdef HAVE_KQUEUE
		void _HandleKqueuePidEvent (struct kevent*);
		#endif

		uint64_t GetCurrentLoopTime() { return MyCurrentLoopTime; }

		// Temporary:
		void _UseEpoll();
		void _UseKqueue();

		bool UsingKqueue() { return bKqueue; }
		bool UsingEpoll() { return bEpoll; }

		void QueueHeartbeat(EventableDescriptor*);
		void ClearHeartbeat(uint64_t, EventableDescriptor*);

		uint64_t GetRealTime();

		bool SetOneShotOnly(bool val) {
			OneShotOnly = val;
		}

	private:
		void _RunOnce();
		void _RunTimers();
		void _UpdateTime();
		void _AddNewDescriptors();
		void _ModifyDescriptors();
		void _InitializeLoopBreaker();
		void _CleanupSockets();

		void _RunSelectOnce();
		void _RunEpollOnce();
		void _RunKqueueOnce();

		void _ModifyEpollEvent (EventableDescriptor*);
		void _DispatchHeartbeats();
		timeval _TimeTilNextEvent();
		void _CleanBadDescriptors();

	public:
		void _ReadLoopBreaker();
		void _ReadInotifyEvents();
        int NumCloseScheduled;

	private:
		enum {
			MaxEpollDescriptors = 64*1024,
			MaxEvents = 4096
		};
		int HeartbeatInterval;
		EMCallback EventCallback;

		class Timer_t: public Bindable_t {
		};

		multimap<uint64_t, Timer_t> Timers;
		multimap<uint64_t, EventableDescriptor*> Heartbeats;
		map<int, Bindable_t*> Files;
		map<int, Bindable_t*> Pids;
		vector<EventableDescriptor*> Descriptors;
		vector<EventableDescriptor*> NewDescriptors;
		set<EventableDescriptor*> ModifiedDescriptors;

		uint64_t NextHeartbeatTime;

		int LoopBreakerReader;
		int LoopBreakerWriter;
		#ifdef OS_WIN32
		struct sockaddr_in LoopBreakerTarget;
		#endif

		timeval Quantum;

		uint64_t MyCurrentLoopTime;

		#ifdef OS_WIN32
		unsigned TickCountTickover;
		unsigned LastTickCount;
		#endif

		bool OneShotOnly;

		#ifdef OS_DARWIN
		mach_timebase_info_data_t mach_timebase;
		#endif

	private:
		bool bTerminateSignalReceived;

		bool bEpoll;
		int epfd; // Epoll file-descriptor
		#ifdef HAVE_EPOLL
		struct epoll_event epoll_events [MaxEvents];
		#endif

		bool bKqueue;
		int kqfd; // Kqueue file-descriptor
		#ifdef HAVE_KQUEUE
		struct kevent Karray [MaxEvents];
		#endif

		InotifyDescriptor *inotify; // pollable descriptor for our inotify instance
};


/*******************
struct SelectData_t
*******************/

struct SelectData_t
{
	SelectData_t();

	int _Select();

	int maxsocket;
	rb_fdset_t fdreads;
	rb_fdset_t fdwrites;
	rb_fdset_t fderrors;
	timeval tv;
	int nSockets;
};

#endif // __EventMachine__H_

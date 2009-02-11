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



#ifdef OS_WIN32
#include "emwin.h"
#endif


// THIS ENTIRE FILE WILL EVENTUALLY BE FOR UNIX BUILDS ONLY.
//#ifdef OS_UNIX

#ifndef __EventMachine__H_
#define __EventMachine__H_

#ifdef BUILD_FOR_RUBY
  #include <ruby.h>
  #define EmSelect rb_thread_select
#else
  #define EmSelect select
#endif


#ifdef OS_UNIX
typedef long long Int64;
#endif
#ifdef OS_WIN32
typedef __int64 Int64;
#endif

extern time_t gCurrentLoopTime;

class EventableDescriptor;


/********************
class EventMachine_t
********************/

class EventMachine_t
{
	public:
		static void SetMaxTimerCount (int);

	public:
		EventMachine_t (void(*event_callback)(const char*, int, const char*, int));
		virtual ~EventMachine_t();

		void Run();
		void ScheduleHalt();
		void SignalLoopBreaker();
		const char *InstallOneshotTimer (int);
		const char *ConnectToServer (const char *, int);
		const char *ConnectToUnixServer (const char *);
		const char *AttachFD (int, bool, bool);

		const char *CreateTcpServer (const char *, int);
		const char *OpenDatagramSocket (const char *, int);
		const char *CreateUnixDomainServer (const char*);
		const char *_OpenFileForWriting (const char*);
		const char *OpenKeyboard();
		//const char *Popen (const char*, const char*);
		const char *Socketpair (char* const*);

		void Add (EventableDescriptor*);
		void Modify (EventableDescriptor*);
		int DetachFD (EventableDescriptor*);
		void ArmKqueueWriter (EventableDescriptor*);
		void ArmKqueueReader (EventableDescriptor*);

		void SetTimerQuantum (int);
		static void SetuidString (const char*);
		static int SetRlimitNofile (int);

		pid_t SubprocessPid;
		int SubprocessExitStatus;

		// Temporary:
		void _UseEpoll();
		void _UseKqueue();


	private:
		bool _RunOnce();
		bool _RunTimers();
		void _AddNewDescriptors();
		void _ModifyDescriptors();
		void _InitializeLoopBreaker();

		bool _RunSelectOnce();
		bool _RunEpollOnce();
		bool _RunKqueueOnce();

		void _ModifyEpollEvent (EventableDescriptor*);

	public:
		void _ReadLoopBreaker();

	private:
		enum {
			HeartbeatInterval = 2,
			MaxEpollDescriptors = 64*1024
		};
		void (*EventCallback)(const char*, int, const char*, int);

		class Timer_t: public Bindable_t {
		};

		multimap<Int64, Timer_t> Timers;
		vector<EventableDescriptor*> Descriptors;
		vector<EventableDescriptor*> NewDescriptors;
		set<EventableDescriptor*> ModifiedDescriptors;

		time_t NextHeartbeatTime;

		int LoopBreakerReader;
		int LoopBreakerWriter;
		#ifdef OS_WIN32
		struct sockaddr_in LoopBreakerTarget;
		#endif

		timeval Quantum;

	private:
		bool bEpoll;
		int epfd; // Epoll file-descriptor

		bool bKqueue;
		int kqfd; // Kqueue file-descriptor
};


/*******************
struct SelectData_t
*******************/

struct SelectData_t
{
	SelectData_t();

	int _Select();

	int maxsocket;
	fd_set fdreads;
	fd_set fdwrites;
	timeval tv;
	int nSockets;
};



#endif // __EventMachine__H_

//#endif // OS_UNIX

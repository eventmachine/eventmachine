/*****************************************************************************

$Id$

File:     cmain.cpp
Date:     06Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/

#include "project.h"


static EventMachine_t *EventMachine;
static int bUseEpoll = 0;
static int bUseKqueue = 0;


/***********************
evma_initialize_library
***********************/

extern "C" void evma_initialize_library (void(*cb)(const char*, int, const char*, int))
{
	// Probably a bad idea to mess with the signal mask of a process
	// we're just being linked into.
	//InstallSignalHandlers();
	if (EventMachine)
		throw std::runtime_error ("already initialized");
	EventMachine = new EventMachine_t (cb);
	if (bUseEpoll)
		EventMachine->_UseEpoll();
	if (bUseKqueue)
		EventMachine->_UseKqueue();
}


/********************
evma_release_library
********************/

extern "C" void evma_release_library()
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	delete EventMachine;
	EventMachine = NULL;
}


/****************
evma_run_machine
****************/

extern "C" void evma_run_machine()
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventMachine->Run();
}


/**************************
evma_install_oneshot_timer
**************************/

extern "C" const char *evma_install_oneshot_timer (int seconds)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->InstallOneshotTimer (seconds);
}


/**********************
evma_connect_to_server
**********************/

extern "C" const char *evma_connect_to_server (const char *server, int port)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->ConnectToServer (server, port);
}

/***************************
evma_connect_to_unix_server
***************************/

extern "C" const char *evma_connect_to_unix_server (const char *server)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->ConnectToUnixServer (server);
}

/**************
evma_attach_fd
**************/

extern "C" const char *evma_attach_fd (int file_descriptor, int notify_readable, int notify_writable)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->AttachFD (file_descriptor, (notify_readable ? true : false), (notify_writable ? true : false));
}

/**************
evma_detach_fd
**************/

extern "C" int evma_detach_fd (const char *binding)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");

	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed)
		return EventMachine->DetachFD (ed);
	else
		throw std::runtime_error ("invalid binding to detach");
}

/**********************
evma_create_tcp_server
**********************/

extern "C" const char *evma_create_tcp_server (const char *address, int port)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->CreateTcpServer (address, port);
}

/******************************
evma_create_unix_domain_server
******************************/

extern "C" const char *evma_create_unix_domain_server (const char *filename)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->CreateUnixDomainServer (filename);
}

/*************************
evma_open_datagram_socket
*************************/

extern "C" const char *evma_open_datagram_socket (const char *address, int port)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->OpenDatagramSocket (address, port);
}

/******************
evma_open_keyboard
******************/

extern "C" const char *evma_open_keyboard()
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->OpenKeyboard();
}



/****************************
evma_send_data_to_connection
****************************/

extern "C" int evma_send_data_to_connection (const char *binding, const char *data, int data_length)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return ConnectionDescriptor::SendDataToConnection (binding, data, data_length);
}

/******************
evma_send_datagram
******************/

extern "C" int evma_send_datagram (const char *binding, const char *data, int data_length, const char *address, int port)
{
  if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return DatagramDescriptor::SendDatagram (binding, data, data_length, address, port);
}


/*********************
evma_close_connection
*********************/

extern "C" void evma_close_connection (const char *binding, int after_writing)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	ConnectionDescriptor::CloseConnection (binding, (after_writing ? true : false));
}

/***********************************
evma_report_connection_error_status
***********************************/

extern "C" int evma_report_connection_error_status (const char *binding)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return ConnectionDescriptor::ReportErrorStatus (binding);
}

/********************
evma_stop_tcp_server
********************/

extern "C" void evma_stop_tcp_server (const char *binding)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	AcceptorDescriptor::StopAcceptor (binding);
}


/*****************
evma_stop_machine
*****************/

extern "C" void evma_stop_machine()
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventMachine->ScheduleHalt();
}


/**************
evma_start_tls
**************/

extern "C" void evma_start_tls (const char *binding)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed)
		ed->StartTls();
}

/******************
evma_set_tls_parms
******************/

extern "C" void evma_set_tls_parms (const char *binding, const char *privatekey_filename, const char *certchain_filename)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed)
		ed->SetTlsParms (privatekey_filename, certchain_filename);
}


/*****************
evma_get_peername
*****************/

extern "C" int evma_get_peername (const char *binding, struct sockaddr *sa)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed) {
		return ed->GetPeername (sa) ? 1 : 0;
	}
	else
		return 0;
}

/*****************
evma_get_sockname
*****************/

extern "C" int evma_get_sockname (const char *binding, struct sockaddr *sa)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed) {
		return ed->GetSockname (sa) ? 1 : 0;
	}
	else
		return 0;
}

/***********************
evma_get_subprocess_pid
***********************/

extern "C" int evma_get_subprocess_pid (const char *binding, pid_t *pid)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed) {
		return ed->GetSubprocessPid (pid) ? 1 : 0;
	}
	else
		return 0;
}

/**************************
evma_get_subprocess_status
**************************/

extern "C" int evma_get_subprocess_status (const char *binding, int *status)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	if (status) {
		*status = EventMachine->SubprocessExitStatus;
		return 1;
	}
	else
		return 0;
}


/*********************
evma_signal_loopbreak
*********************/

extern "C" void evma_signal_loopbreak()
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventMachine->SignalLoopBreaker();
}



/****************
evma__write_file
****************/

extern "C" const char *evma__write_file (const char *filename)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->_OpenFileForWriting (filename);
}


/********************************
evma_get_comm_inactivity_timeout
********************************/

extern "C" int evma_get_comm_inactivity_timeout (const char *binding, int *value)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed) {
		return ed->GetCommInactivityTimeout (value);
	}
	else
		return 0; //Perhaps this should be an exception. Access to an unknown binding.
}

/********************************
evma_set_comm_inactivity_timeout
********************************/

extern "C" int evma_set_comm_inactivity_timeout (const char *binding, int *value)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	if (ed) {
		return ed->SetCommInactivityTimeout (value);
	}
	else
		return 0; //Perhaps this should be an exception. Access to an unknown binding.
}


/**********************
evma_set_timer_quantum
**********************/

extern "C" void evma_set_timer_quantum (int interval)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventMachine->SetTimerQuantum (interval);
}

/************************
evma_set_max_timer_count
************************/

extern "C" void evma_set_max_timer_count (int ct)
{
	// This may only be called if the reactor is not running.
	if (EventMachine)
		throw std::runtime_error ("already initialized");
	EventMachine_t::SetMaxTimerCount (ct);
}

/******************
evma_setuid_string
******************/

extern "C" void evma_setuid_string (const char *username)
{
    // We do NOT need to be running an EM instance because this method is static.
    EventMachine_t::SetuidString (username);
}


/**********
evma_popen
**********/

extern "C" const char *evma_popen (char * const*cmd_strings)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	return EventMachine->Socketpair (cmd_strings);
}


/***************************
evma_get_outbound_data_size
***************************/

extern "C" int evma_get_outbound_data_size (const char *binding)
{
	if (!EventMachine)
		throw std::runtime_error ("not initialized");
	EventableDescriptor *ed = dynamic_cast <EventableDescriptor*> (Bindable_t::GetObject (binding));
	return ed ? ed->GetOutboundDataSize() : 0;
}


/***********
evma__epoll
***********/

extern "C" void evma__epoll()
{
	bUseEpoll = 1;
}

/************
evma__kqueue
************/

extern "C" void evma__kqueue()
{
	bUseKqueue = 1;
}


/**********************
evma_set_rlimit_nofile
**********************/

extern "C" int evma_set_rlimit_nofile (int nofiles)
{
	return EventMachine_t::SetRlimitNofile (nofiles);
}


/*********************************
evma_send_file_data_to_connection
*********************************/

extern "C" int evma_send_file_data_to_connection (const char *binding, const char *filename)
{
	/* This is a sugaring over send_data_to_connection that reads a file into a
	 * locally-allocated buffer, and sends the file data to the remote peer.
	 * Return the number of bytes written to the caller.
	 * TODO, needs to impose a limit on the file size. This is intended only for
	 * small files. (I don't know, maybe 8K or less.) For larger files, use interleaved
	 * I/O to avoid slowing the rest of the system down.
	 * TODO: we should return a code rather than barf, in case of file-not-found.
	 * TODO, does this compile on Windows?
	 * TODO, given that we want this to work only with small files, how about allocating
	 * the buffer on the stack rather than the heap?
	 *
	 * Modified 25Jul07. This now returns -1 on file-too-large; 0 for success, and a positive
	 * errno in case of other errors.
	 *
	/* Contributed by Kirk Haines.
	 */

	char data[32*1024];
	int r;

	if (!EventMachine)
		throw std::runtime_error("not initialized");

	int Fd = open (filename, O_RDONLY);

	if (Fd < 0)
		return errno;
	// From here on, all early returns MUST close Fd.

	struct stat st;
	if (fstat (Fd, &st)) {
		int e = errno;
		close (Fd);
		return e;
	}

	int filesize = st.st_size;
	if (filesize <= 0) {
		close (Fd);
		return 0;
	}
	else if (filesize > sizeof(data)) {
		close (Fd);
		return -1;
	}


	r = read (Fd, data, filesize);
	if (r != filesize) {
		int e = errno;
		close (Fd);
		return e;
	}
	evma_send_data_to_connection (binding, data, r);
	close (Fd);

	return 0;
}





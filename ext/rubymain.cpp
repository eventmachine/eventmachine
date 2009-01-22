/*****************************************************************************

$Id$

File:     rubymain.cpp
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
#include "eventmachine.h"
#include <ruby.h>



/*******
Statics
*******/

static VALUE EmModule;
static VALUE EmConnection;

static VALUE Intern_at_signature;
static VALUE Intern_at_timers;
static VALUE Intern_at_conns;
static VALUE Intern_event_callback;
static VALUE Intern_run_deferred_callbacks;
static VALUE Intern_delete;
static VALUE Intern_call;
static VALUE Intern_receive_data;

static VALUE Intern_notify_readable;
static VALUE Intern_notify_writable;

/****************
t_event_callback
****************/

static void event_callback (const char *a1, int a2, const char *a3, int a4)
{
	if (a2 == EM_CONNECTION_READ) {
		VALUE t = rb_ivar_get (EmModule, Intern_at_conns);
		VALUE q = rb_hash_aref (t, rb_str_new2(a1));
		if (q == Qnil)
			rb_raise (rb_eRuntimeError, "no connection");
		rb_funcall (q, Intern_receive_data, 1, rb_str_new (a3, a4));
	}
	else if (a2 == EM_CONNECTION_NOTIFY_READABLE) {
		VALUE t = rb_ivar_get (EmModule, Intern_at_conns);
		VALUE q = rb_hash_aref (t, rb_str_new2(a1));
		if (q == Qnil)
			rb_raise (rb_eRuntimeError, "no connection");
		rb_funcall (q, Intern_notify_readable, 0);
	}
	else if (a2 == EM_CONNECTION_NOTIFY_WRITABLE) {
		VALUE t = rb_ivar_get (EmModule, Intern_at_conns);
		VALUE q = rb_hash_aref (t, rb_str_new2(a1));
		if (q == Qnil)
			rb_raise (rb_eRuntimeError, "no connection");
		rb_funcall (q, Intern_notify_writable, 0);
	}
	else if (a2 == EM_LOOPBREAK_SIGNAL) {
		rb_funcall (EmModule, Intern_run_deferred_callbacks, 0);
	}
	else if (a2 == EM_TIMER_FIRED) {
		VALUE t = rb_ivar_get (EmModule, Intern_at_timers);
		VALUE q = rb_funcall (t, Intern_delete, 1, rb_str_new(a3, a4));
		if (q == Qnil)
			rb_raise (rb_eRuntimeError, "no timer");
		rb_funcall (q, Intern_call, 0);
	}
	else
		rb_funcall (EmModule, Intern_event_callback, 3, rb_str_new2(a1), (a2 << 1) | 1, rb_str_new(a3,a4));
}



/**************************
t_initialize_event_machine
**************************/

static VALUE t_initialize_event_machine (VALUE self)
{
	evma_initialize_library (event_callback);
	return Qnil;
}



/*****************************
t_run_machine_without_threads
*****************************/

static VALUE t_run_machine_without_threads (VALUE self)
{
	evma_run_machine();
	return Qnil;
}


/*******************
t_add_oneshot_timer
*******************/

static VALUE t_add_oneshot_timer (VALUE self, VALUE interval)
{
	const char *f = evma_install_oneshot_timer (FIX2INT (interval));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no timer");
	return rb_str_new2 (f);
}


/**************
t_start_server
**************/

static VALUE t_start_server (VALUE self, VALUE server, VALUE port)
{
	const char *f = evma_create_tcp_server (StringValuePtr(server), FIX2INT(port));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no acceptor");
	return rb_str_new2 (f);
}

/*************
t_stop_server
*************/

static VALUE t_stop_server (VALUE self, VALUE signature)
{
	evma_stop_tcp_server (StringValuePtr (signature));
	return Qnil;
}


/*******************
t_start_unix_server
*******************/

static VALUE t_start_unix_server (VALUE self, VALUE filename)
{
	const char *f = evma_create_unix_domain_server (StringValuePtr(filename));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no unix-domain acceptor");
	return rb_str_new2 (f);
}



/***********
t_send_data
***********/

static VALUE t_send_data (VALUE self, VALUE signature, VALUE data, VALUE data_length)
{
	int b = evma_send_data_to_connection (StringValuePtr (signature), StringValuePtr (data), FIX2INT (data_length));
	return INT2NUM (b);
}


/***********
t_start_tls
***********/

static VALUE t_start_tls (VALUE self, VALUE signature)
{
	evma_start_tls (StringValuePtr (signature));
	return Qnil;
}

/***************
t_set_tls_parms
***************/

static VALUE t_set_tls_parms (VALUE self, VALUE signature, VALUE privkeyfile, VALUE certchainfile)
{
	/* set_tls_parms takes a series of positional arguments for specifying such things
	 * as private keys and certificate chains.
	 * It's expected that the parameter list will grow as we add more supported features.
	 * ALL of these parameters are optional, and can be specified as empty or NULL strings.
	 */
	evma_set_tls_parms (StringValuePtr (signature), StringValuePtr (privkeyfile), StringValuePtr (certchainfile) );
	return Qnil;
}

/**************
t_get_peername
**************/

static VALUE t_get_peername (VALUE self, VALUE signature)
{
	struct sockaddr s;
	if (evma_get_peername (StringValuePtr (signature), &s)) {
		return rb_str_new ((const char*)&s, sizeof(s));
	}

	return Qnil;
}

/**************
t_get_sockname
**************/

static VALUE t_get_sockname (VALUE self, VALUE signature)
{
	struct sockaddr s;
	if (evma_get_sockname (StringValuePtr (signature), &s)) {
		return rb_str_new ((const char*)&s, sizeof(s));
	}

	return Qnil;
}

/********************
t_get_subprocess_pid
********************/

static VALUE t_get_subprocess_pid (VALUE self, VALUE signature)
{
	pid_t pid;
	if (evma_get_subprocess_pid (StringValuePtr (signature), &pid)) {
		return INT2NUM (pid);
	}

	return Qnil;
}

/***********************
t_get_subprocess_status
***********************/

static VALUE t_get_subprocess_status (VALUE self, VALUE signature)
{
	int status;
	if (evma_get_subprocess_status (StringValuePtr (signature), &status)) {
		return INT2NUM (status);
	}

	return Qnil;
}

/*****************************
t_get_comm_inactivity_timeout
*****************************/

static VALUE t_get_comm_inactivity_timeout (VALUE self, VALUE signature)
{
	int timeout;
	if (evma_get_comm_inactivity_timeout (StringValuePtr (signature), &timeout))
		return INT2FIX (timeout);
	return Qnil;
}

/*****************************
t_set_comm_inactivity_timeout
*****************************/

static VALUE t_set_comm_inactivity_timeout (VALUE self, VALUE signature, VALUE timeout)
{
	int ti = FIX2INT (timeout);
	if (evma_set_comm_inactivity_timeout (StringValuePtr (signature), &ti));
		return Qtrue;
	return Qnil;
}


/***************
t_send_datagram
***************/

static VALUE t_send_datagram (VALUE self, VALUE signature, VALUE data, VALUE data_length, VALUE address, VALUE port)
{
	int b = evma_send_datagram (StringValuePtr (signature), StringValuePtr (data), FIX2INT (data_length), StringValuePtr(address), FIX2INT(port));
	return INT2NUM (b);
}


/******************
t_close_connection
******************/

static VALUE t_close_connection (VALUE self, VALUE signature, VALUE after_writing)
{
	evma_close_connection (StringValuePtr (signature), ((after_writing == Qtrue) ? 1 : 0));
	return Qnil;
}

/********************************
t_report_connection_error_status
********************************/

static VALUE t_report_connection_error_status (VALUE self, VALUE signature)
{
	int b = evma_report_connection_error_status (StringValuePtr (signature));
	return INT2NUM (b);
}



/****************
t_connect_server
****************/

static VALUE t_connect_server (VALUE self, VALUE server, VALUE port)
{
	// Avoid FIX2INT in this case, because it doesn't deal with type errors properly.
	// Specifically, if the value of port comes in as a string rather than an integer,
	// NUM2INT will throw a type error, but FIX2INT will generate garbage.

	const char *f = evma_connect_to_server (StringValuePtr(server), NUM2INT(port));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no connection");
	return rb_str_new2 (f);
}

/*********************
t_connect_unix_server
*********************/

static VALUE t_connect_unix_server (VALUE self, VALUE serversocket)
{
	const char *f = evma_connect_to_unix_server (StringValuePtr(serversocket));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no connection");
	return rb_str_new2 (f);
}

/***********
t_attach_fd
***********/

static VALUE t_attach_fd (VALUE self, VALUE file_descriptor, VALUE read_mode, VALUE write_mode)
{
	const char *f = evma_attach_fd (NUM2INT(file_descriptor), (read_mode == Qtrue) ? 1 : 0, (write_mode == Qtrue) ? 1 : 0);
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no connection");
	return rb_str_new2 (f);
}

/***********
t_detach_fd
***********/

static VALUE t_detach_fd (VALUE self,  VALUE signature)
{
	return INT2NUM(evma_detach_fd (StringValuePtr(signature)));
}

/*****************
t_open_udp_socket
*****************/

static VALUE t_open_udp_socket (VALUE self, VALUE server, VALUE port)
{
	const char *f = evma_open_datagram_socket (StringValuePtr(server), FIX2INT(port));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no datagram socket");
	return rb_str_new2 (f);
}



/*****************
t_release_machine
*****************/

static VALUE t_release_machine (VALUE self)
{
	evma_release_library();
	return Qnil;
}


/******
t_stop
******/

static VALUE t_stop (VALUE self)
{
	evma_stop_machine();
	return Qnil;
}

/******************
t_signal_loopbreak
******************/

static VALUE t_signal_loopbreak (VALUE self)
{
	evma_signal_loopbreak();
	return Qnil;
}

/**************
t_library_type
**************/

static VALUE t_library_type (VALUE self)
{
	return rb_eval_string (":extension");
}



/*******************
t_set_timer_quantum
*******************/

static VALUE t_set_timer_quantum (VALUE self, VALUE interval)
{
  evma_set_timer_quantum (FIX2INT (interval));
  return Qnil;
}

/********************
t_set_max_timer_count
********************/

static VALUE t_set_max_timer_count (VALUE self, VALUE ct)
{
  evma_set_max_timer_count (FIX2INT (ct));
  return Qnil;
}

/***************
t_setuid_string
***************/

static VALUE t_setuid_string (VALUE self, VALUE username)
{
  evma_setuid_string (StringValuePtr (username));
  return Qnil;
}



/*************
t__write_file
*************/

static VALUE t__write_file (VALUE self, VALUE filename)
{
	const char *f = evma__write_file (StringValuePtr (filename));
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "file not opened");
	return rb_str_new2 (f);
}

/**************
t_invoke_popen
**************/

static VALUE t_invoke_popen (VALUE self, VALUE cmd)
{
	// 1.8.7+
	#ifdef RARRAY_LEN
		int len = RARRAY_LEN(cmd);
	#else
		int len = RARRAY (cmd)->len;
	#endif
	if (len > 98)
		rb_raise (rb_eRuntimeError, "too many arguments to popen");
	char *strings [100];
	for (int i=0; i < len; i++) {
		VALUE ix = INT2FIX (i);
		VALUE s = rb_ary_aref (1, &ix, cmd);
		strings[i] = StringValuePtr (s);
	}
	strings[len] = NULL;

	const char *f = evma_popen (strings);
	if (!f || !*f) {
		char *err = strerror (errno);
		char buf[100];
		memset (buf, 0, sizeof(buf));
		snprintf (buf, sizeof(buf)-1, "no popen: %s", (err?err:"???"));
		rb_raise (rb_eRuntimeError, buf);
	}
	return rb_str_new2 (f);
}


/***************
t_read_keyboard
***************/

static VALUE t_read_keyboard (VALUE self)
{
	const char *f = evma_open_keyboard();
	if (!f || !*f)
		rb_raise (rb_eRuntimeError, "no keyboard reader");
	return rb_str_new2 (f);
}


/********
t__epoll
********/

static VALUE t__epoll (VALUE self)
{
	// Temporary.
	evma__epoll();
	return Qnil;
}

/*********
t__kqueue
*********/

static VALUE t__kqueue (VALUE self)
{
	// Temporary.
	evma__kqueue();
	return Qnil;
}


/****************
t_send_file_data
****************/

static VALUE t_send_file_data (VALUE self, VALUE signature, VALUE filename)
{

	/* The current implementation of evma_send_file_data_to_connection enforces a strict
	 * upper limit on the file size it will transmit (currently 32K). The function returns
	 * zero on success, -1 if the requested file exceeds its size limit, and a positive
	 * number for other errors.
	 * TODO: Positive return values are actually errno's, which is probably the wrong way to
	 * do this. For one thing it's ugly. For another, we can't be sure zero is never a real errno.
	 */

	int b = evma_send_file_data_to_connection (StringValuePtr(signature), StringValuePtr(filename));
	if (b == -1)
		rb_raise(rb_eRuntimeError, "File too large.  send_file_data() supports files under 32k.");
	if (b > 0) {
		char *err = strerror (b);
		char buf[1024];
		memset (buf, 0, sizeof(buf));
		snprintf (buf, sizeof(buf)-1, ": %s %s", StringValuePtr(filename),(err?err:"???"));

		rb_raise (rb_eIOError, buf);
	}

	return INT2NUM (0);
}


/*******************
t_set_rlimit_nofile
*******************/

static VALUE t_set_rlimit_nofile (VALUE self, VALUE arg)
{
	arg = (NIL_P(arg)) ? -1 : NUM2INT (arg);
	return INT2NUM (evma_set_rlimit_nofile (arg));
}

/***************************
conn_get_outbound_data_size
***************************/

static VALUE conn_get_outbound_data_size (VALUE self)
{
	VALUE sig = rb_ivar_get (self, Intern_at_signature);
	return INT2NUM (evma_get_outbound_data_size (StringValuePtr(sig)));
}


/******************************
conn_associate_callback_target
******************************/

static VALUE conn_associate_callback_target (VALUE self, VALUE sig)
{
	// No-op for the time being.
	return Qnil;
}


/***************
t_get_loop_time
****************/

static VALUE t_get_loop_time (VALUE self)
{
  VALUE cTime = rb_path2class("Time");
  if (gCurrentLoopTime != 0) {
    return rb_funcall(cTime,
                      rb_intern("at"),
                      1,
                      INT2NUM(gCurrentLoopTime));
  }
  return Qnil;
}


/*********************
Init_rubyeventmachine
*********************/

extern "C" void Init_rubyeventmachine()
{
	// Tuck away some symbol values so we don't have to look 'em up every time we need 'em.
	Intern_at_signature = rb_intern ("@signature");
	Intern_at_timers = rb_intern ("@timers");
	Intern_at_conns = rb_intern ("@conns");

	Intern_event_callback = rb_intern ("event_callback");
	Intern_run_deferred_callbacks = rb_intern ("run_deferred_callbacks");
	Intern_delete = rb_intern ("delete");
	Intern_call = rb_intern ("call");
	Intern_receive_data = rb_intern ("receive_data");

	Intern_notify_readable = rb_intern ("notify_readable");
	Intern_notify_writable = rb_intern ("notify_writable");

	// INCOMPLETE, we need to define class Connections inside module EventMachine
	// run_machine and run_machine_without_threads are now identical.
	// Must deprecate the without_threads variant.
	EmModule = rb_define_module ("EventMachine");
	EmConnection = rb_define_class_under (EmModule, "Connection", rb_cObject);

	rb_define_class_under (EmModule, "ConnectionNotBound", rb_eException);
	rb_define_class_under (EmModule, "NoHandlerForAcceptedConnection", rb_eException);
	rb_define_class_under (EmModule, "UnknownTimerFired", rb_eException);

	rb_define_module_function (EmModule, "initialize_event_machine", (VALUE(*)(...))t_initialize_event_machine, 0);
	rb_define_module_function (EmModule, "run_machine", (VALUE(*)(...))t_run_machine_without_threads, 0);
	rb_define_module_function (EmModule, "run_machine_without_threads", (VALUE(*)(...))t_run_machine_without_threads, 0);
	rb_define_module_function (EmModule, "add_oneshot_timer", (VALUE(*)(...))t_add_oneshot_timer, 1);
	rb_define_module_function (EmModule, "start_tcp_server", (VALUE(*)(...))t_start_server, 2);
	rb_define_module_function (EmModule, "stop_tcp_server", (VALUE(*)(...))t_stop_server, 1);
	rb_define_module_function (EmModule, "start_unix_server", (VALUE(*)(...))t_start_unix_server, 1);
	rb_define_module_function (EmModule, "set_tls_parms", (VALUE(*)(...))t_set_tls_parms, 3);
	rb_define_module_function (EmModule, "start_tls", (VALUE(*)(...))t_start_tls, 1);
	rb_define_module_function (EmModule, "send_data", (VALUE(*)(...))t_send_data, 3);
	rb_define_module_function (EmModule, "send_datagram", (VALUE(*)(...))t_send_datagram, 5);
	rb_define_module_function (EmModule, "close_connection", (VALUE(*)(...))t_close_connection, 2);
	rb_define_module_function (EmModule, "report_connection_error_status", (VALUE(*)(...))t_report_connection_error_status, 1);
	rb_define_module_function (EmModule, "connect_server", (VALUE(*)(...))t_connect_server, 2);
	rb_define_module_function (EmModule, "connect_unix_server", (VALUE(*)(...))t_connect_unix_server, 1);

	rb_define_module_function (EmModule, "attach_fd", (VALUE (*)(...))t_attach_fd, 3);
	rb_define_module_function (EmModule, "detach_fd", (VALUE (*)(...))t_detach_fd, 1);

	rb_define_module_function (EmModule, "current_time", (VALUE(*)(...))t_get_loop_time, 0);

	rb_define_module_function (EmModule, "open_udp_socket", (VALUE(*)(...))t_open_udp_socket, 2);
	rb_define_module_function (EmModule, "read_keyboard", (VALUE(*)(...))t_read_keyboard, 0);
	rb_define_module_function (EmModule, "release_machine", (VALUE(*)(...))t_release_machine, 0);
	rb_define_module_function (EmModule, "stop", (VALUE(*)(...))t_stop, 0);
	rb_define_module_function (EmModule, "signal_loopbreak", (VALUE(*)(...))t_signal_loopbreak, 0);
	rb_define_module_function (EmModule, "library_type", (VALUE(*)(...))t_library_type, 0);
	rb_define_module_function (EmModule, "set_timer_quantum", (VALUE(*)(...))t_set_timer_quantum, 1);
	rb_define_module_function (EmModule, "set_max_timer_count", (VALUE(*)(...))t_set_max_timer_count, 1);
	rb_define_module_function (EmModule, "setuid_string", (VALUE(*)(...))t_setuid_string, 1);
	rb_define_module_function (EmModule, "invoke_popen", (VALUE(*)(...))t_invoke_popen, 1);
	rb_define_module_function (EmModule, "send_file_data", (VALUE(*)(...))t_send_file_data, 2);

	// Provisional:
	rb_define_module_function (EmModule, "_write_file", (VALUE(*)(...))t__write_file, 1);

	rb_define_module_function (EmModule, "get_peername", (VALUE(*)(...))t_get_peername, 1);
	rb_define_module_function (EmModule, "get_sockname", (VALUE(*)(...))t_get_sockname, 1);
	rb_define_module_function (EmModule, "get_subprocess_pid", (VALUE(*)(...))t_get_subprocess_pid, 1);
	rb_define_module_function (EmModule, "get_subprocess_status", (VALUE(*)(...))t_get_subprocess_status, 1);
	rb_define_module_function (EmModule, "get_comm_inactivity_timeout", (VALUE(*)(...))t_get_comm_inactivity_timeout, 1);
	rb_define_module_function (EmModule, "set_comm_inactivity_timeout", (VALUE(*)(...))t_set_comm_inactivity_timeout, 2);
	rb_define_module_function (EmModule, "set_rlimit_nofile", (VALUE(*)(...))t_set_rlimit_nofile, 1);

	// Temporary:
	rb_define_module_function (EmModule, "epoll", (VALUE(*)(...))t__epoll, 0);
	rb_define_module_function (EmModule, "kqueue", (VALUE(*)(...))t__kqueue, 0);

	rb_define_method (EmConnection, "get_outbound_data_size", (VALUE(*)(...))conn_get_outbound_data_size, 0);
	rb_define_method (EmConnection, "associate_callback_target", (VALUE(*)(...))conn_associate_callback_target, 1);

	rb_define_const (EmModule, "TimerFired", INT2NUM(100));
	rb_define_const (EmModule, "ConnectionData", INT2NUM(101));
	rb_define_const (EmModule, "ConnectionUnbound", INT2NUM(102));
	rb_define_const (EmModule, "ConnectionAccepted", INT2NUM(103));
	rb_define_const (EmModule, "ConnectionCompleted", INT2NUM(104));
	rb_define_const (EmModule, "LoopbreakSignalled", INT2NUM(105));

	rb_define_const (EmModule, "ConnectionNotifyReadable", INT2NUM(106));
	rb_define_const (EmModule, "ConnectionNotifyWritable", INT2NUM(107));

}


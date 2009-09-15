#include "project.h"
#include <ruby.h>
#include "em.h"
#include "ed.h"

#ifndef RFLOAT_VALUE
#define RFLOAT_VALUE(arg) RFLOAT(arg)->value
#endif
#ifndef RSTRING_LEN
#define RSTRING_LEN(arg) RSTRING(arg)->len
#endif
#ifndef RSTRING_PTR
#define RSTRING_PTR(arg) RSTRING(arg)->ptr
#endif
#ifndef RARRAY_LEN
#define RARRAY_LEN(arg) RARRAY(arg)->len
#endif

static VALUE EmModule;
static VALUE EmConnection;
static VALUE EmIPConnection;
static VALUE EmTCPConnection;
static VALUE EmUDPConnection;
static VALUE EmReactor;
static VALUE EmTCPServer;

static VALUE rb_cSocket;

static VALUE Intern_run_deferred_callbacks;
static VALUE Intern_at_timers;
static VALUE Intern_call;
static VALUE Intern_connection_completed;
static VALUE Intern_reactor;
static VALUE Intern_receive_data;
static VALUE Intern_initialize;
static VALUE Intern_unbind;
static VALUE Intern_notify_readable;
static VALUE Intern_notify_writable;
static VALUE Intern_ssl_handshake_completed;
static VALUE Intern_proxy_target_unbound;
static VALUE Intern_ssl_verify_peer;
static VALUE Intern_new;
static VALUE Intern_unpack_sockaddr_in;

static void evma_callback_loopbreak(VALUE reactor)
{
  rb_funcall(reactor, Intern_run_deferred_callbacks, 0);
}

static void evma_callback_timer(VALUE reactor, const unsigned long sig)
{
  VALUE t = rb_ivar_get (reactor, Intern_at_timers);
  VALUE q = rb_hash_delete(t, ULONG2NUM (sig));
  if (q == Qnil) {
  //rb_raise (EM_eUnknownTimerFired, "no such timer: %lu", a4);
  } else if (q == Qfalse) {
  /* Timer Canceled */
  } else {
    rb_funcall (q, Intern_call, 0);
	}
}

static void evma_callback_completed(VALUE conn)
{
  rb_funcall(conn, Intern_connection_completed, 0);
}

static void evma_callback_receive(VALUE conn, const char *data, const unsigned long len)
{
  rb_funcall(conn, Intern_receive_data, 1, rb_str_new(data, len));
}

static void evma_callback_unbind(VALUE conn)
{
  rb_funcall(conn, Intern_unbind, 0);
  DATA_PTR(conn) = NULL;
}

static void evma_callback_accept(VALUE acceptor, ConnectionDescriptor *cd)
{
  AcceptorDescriptor *ad = (AcceptorDescriptor*) DATA_PTR(acceptor);
  VALUE handler = ad->GetHandler();
  VALUE argv = ad->GetHandlerArgv();
  int argc = RARRAY_LEN(argv);
  VALUE conn = Data_Wrap_Struct(handler, NULL, NULL, cd);
  cd->SetBinding(conn);
  rb_ivar_set(conn, Intern_reactor, cd->GetReactor()->GetBinding());

  if (argc > 0) {
    VALUE callargs[argc];
    for (int i=0; i < argc; i++) {
      callargs[i] = rb_ary_shift(argv);
    }
    rb_funcall2(conn, Intern_initialize, argc, callargs);
  }
	else {
		rb_funcall(conn, Intern_initialize, 0);
	}
}

static void evma_callback_notify_readable(VALUE conn)
{
  rb_funcall(conn, Intern_notify_readable, 0);
}

static void evma_callback_notify_writable(VALUE conn)
{
  rb_funcall(conn, Intern_notify_writable, 0);
}

static void evma_callback_ssl_handshake_completed(VALUE conn)
{
  rb_funcall(conn, Intern_ssl_handshake_completed, 0);
}

static void evma_callback_proxy_target_unbound(VALUE conn)
{
  rb_funcall(conn, Intern_proxy_target_unbound, 0);
}

static void evma_callback_ssl_verify_peer(VALUE conn, const char *str, const unsigned long len)
{
  VALUE r = rb_funcall(conn, Intern_ssl_verify_peer, 1, rb_str_new(str, len));
  if (RTEST(r)) {
    ConnectionDescriptor *cd = (ConnectionDescriptor*) DATA_PTR(conn);
    cd->AcceptSslPeer();
  }
}

static void event_callback (const unsigned long a1, int a2, const char *a3, const unsigned long a4)
{
  if (a2 == EM_LOOPBREAK_SIGNAL) {
    evma_callback_loopbreak((VALUE) a1);
  }
  else if (a2 == EM_TIMER_FIRED) {
    evma_callback_timer((VALUE) a1, a4);
  }
  else if (a2 == EM_CONNECTION_COMPLETED) {
    evma_callback_completed((VALUE) a1);
  }
  else if (a2 == EM_CONNECTION_READ) {
    evma_callback_receive((VALUE) a1, a3, a4);
  }
  else if (a2 == EM_CONNECTION_UNBOUND) {
    evma_callback_unbind((VALUE) a1);
  }
  else if (a2 == EM_CONNECTION_ACCEPTED) {
    evma_callback_accept((VALUE) a1, (ConnectionDescriptor*) a3);
  }
  else if (a2 == EM_CONNECTION_NOTIFY_READABLE) {
    evma_callback_notify_readable((VALUE) a1);
  }
  else if (a2 == EM_CONNECTION_NOTIFY_WRITABLE) {
    evma_callback_notify_writable((VALUE) a1);
  }
  else if (a2 == EM_SSL_HANDSHAKE_COMPLETED) {
    evma_callback_ssl_handshake_completed((VALUE) a1);
  }
  else if (a2 == EM_PROXY_TARGET_UNBOUND) {
    evma_callback_proxy_target_unbound((VALUE) a1);
  }
  else if (a2 == EM_SSL_VERIFY) {
    evma_callback_ssl_verify_peer((VALUE) a1, a3, a4);
  }
}

EventMachine_t* ensure_machine(VALUE reactor, const char *msg)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  if (em == NULL)
    rb_raise(rb_eRuntimeError, "%s called on a released reactor", msg);
  return em;
}

EventableDescriptor* ensure_connection(VALUE conn, const char *msg)
{
  EventableDescriptor *ed = (EventableDescriptor*) DATA_PTR(conn);
  if (ed == NULL)
    rb_raise(rb_eRuntimeError, "%s called on an unbound connection", msg);
  return ed;
}

static VALUE build_handler(VALUE handler, VALUE baseklass)
{
  if (RTEST(handler)) {
    if (rb_obj_is_kind_of(handler, rb_cClass) == Qtrue) {
      if (!rb_class_inherited_p(handler, baseklass))
        rb_raise(rb_eArgError, "must provide module or subclass of EventMachine::%s", rb_class2name(baseklass));
      return handler;
    }
    else {
      VALUE anon_klass = rb_funcall(rb_cClass, Intern_new, 1, baseklass);
      rb_include_module(anon_klass, handler);
      return anon_klass;
    }
  }
  return baseklass;
}

static VALUE reactor_release(VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#release");
  // Unbind callbacks can't call back on the reactor object during destruction or Ruby will explode.
  size_t i;
  vector<EventableDescriptor*> desc = em->GetDescriptors();
  vector<EventableDescriptor*> desc2 = em->GetNewDescriptors();

  for (i=0; i < desc.size(); i++) {
    desc[i]->DisableUnbind();
  }
  for (i=0; i < desc2.size(); i++) {
    desc2[i]->DisableUnbind();
  }
  DATA_PTR(reactor) = NULL;
  delete em;
  return Qnil;
}

void reactor_free(EventMachine_t *reactor)
{
  if (reactor)
    reactor_release(reactor->GetBinding());
}

void reactor_mark(EventMachine_t *reactor)
{
  if (reactor == NULL)
    return;
  size_t i;
  vector<EventableDescriptor*> desc = reactor->GetDescriptors();
  vector<EventableDescriptor*> desc2 = reactor->GetNewDescriptors();

  for (i=0; i < desc.size(); i++) {
    rb_gc_mark(desc[i]->GetBinding());
  }
  for (i=0; i < desc2.size(); i++) {
    rb_gc_mark(desc2[i]->GetBinding());
  }
}

static VALUE reactor_alloc(VALUE klass)
{
  EventMachine_t *em = new EventMachine_t(event_callback);
  VALUE emobj = Data_Wrap_Struct(klass, reactor_mark, reactor_free, em);
  em->SetBinding(emobj);
  em->_UseEpoll();
  return emobj;
}

void acceptor_mark(AcceptorDescriptor *ad)
{
  VALUE handler = ad->GetHandler();
  VALUE argv = ad->GetHandlerArgv();

  if ((void*)handler != NULL)
    rb_gc_mark(handler);
  if ((void*)argv != NULL)
    rb_gc_mark(argv);
}

static VALUE reactor_signal_loopbreak(VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#signal_loopbreak");
  em->SignalLoopBreaker();
  return Qnil;
}

static VALUE reactor_run(VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#run");
  em->Run();
  return Qnil;
}

static VALUE reactor_stop(VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#stop");
  em->ScheduleHalt();
  rb_funcall(reactor, rb_intern("machine_stopped"), 0);
  return Qnil;
}

static VALUE reactor_add_timer(VALUE reactor, VALUE interval)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#add_timer");
  return ULONG2NUM(em->InstallOneshotTimer(FIX2INT(interval)));
}

static VALUE reactor_connect_tcp(int argc, VALUE *argv, VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#connect");
  VALUE server;
  VALUE port;
  VALUE handler;
  VALUE extra;
  rb_scan_args(argc, argv, "21*", &server, &port, &handler, &extra);
  ConnectionDescriptor *cd = em->ConnectToServer(NULL, 0, StringValuePtr(server), FIX2INT(port));

  // This stuff should be moved into another function for generic handler instantiation
  if (cd) {
    VALUE real_handler = build_handler(handler, EmTCPConnection);
    VALUE cdobj = Data_Wrap_Struct(real_handler, NULL, NULL, cd);
    rb_ivar_set(cdobj, Intern_reactor, cd->GetReactor()->GetBinding());

    // Pass extra arguments to the handler's initialize
    if (argc > 3) {
      int callargc = argc-3;
      VALUE callargv[callargc];
      for (int i=0; i < callargc; i++) {
        callargv[i] = rb_ary_shift(extra);
      }
      rb_funcall2(cdobj, Intern_initialize, callargc, callargv);
    }
		else {
			rb_funcall(cdobj, Intern_initialize, 0);
		}

    cd->SetBinding(cdobj);
    return cdobj;
  }
  return Qnil;
}

static VALUE reactor_start_tcp_server(int argc, VALUE *argv, VALUE reactor)
{
  EventMachine_t *em = ensure_machine(reactor, "Reactor#start_server");
  VALUE server;
  VALUE port;
  VALUE handler;
  VALUE extra;
  rb_scan_args(argc, argv, "21*", &server, &port, &handler, &extra);
  AcceptorDescriptor *ad = em->CreateTcpServer(RSTRING_PTR(server), FIX2INT(port));
  if (!ad)
    rb_sys_fail("start_server failed");
  ad->SetHandler(build_handler(handler, EmTCPConnection));
  ad->SetHandlerArgv(extra);
  VALUE adobj = Data_Wrap_Struct(EmTCPServer, acceptor_mark, NULL, ad);
  rb_ivar_set(adobj, Intern_reactor, ad->GetReactor()->GetBinding());
  ad->SetBinding(adobj);
  return adobj;
}

static VALUE conn_close_connection(int argc, VALUE *argv, VALUE conn)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#close_connection");
  VALUE after_writing = Qfalse;
  rb_scan_args(argc, argv, "01", &after_writing);
  ed->ScheduleClose((after_writing == Qtrue) ? true : false);
  return Qnil;
}

static VALUE conn_proxy_incoming_to(VALUE conn, VALUE target)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#proxy_incoming_to");
  EventableDescriptor *targetptr = (EventableDescriptor*) DATA_PTR(target);
  if (targetptr == NULL)
    rb_raise(rb_eRuntimeError, "Connection#proxy_incoming_to called with an unbound target connection");
  ed->StartProxy(targetptr);
  return Qnil;
}

static VALUE conn_stop_proxy(VALUE conn)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#stop_proxy");
  ed->StopProxy();
  return Qnil;
}

static VALUE conn_send_data(VALUE conn, VALUE data)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#send_data");
  return INT2NUM(ed->SendOutboundData(RSTRING_PTR(data), RSTRING_LEN(data)));
}

static VALUE conn_get_peername(VALUE conn)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#get_peername");
  struct sockaddr s;
  bool success = ed->GetPeername(&s);
  // ConnectionDescriptor uses the getpeername() call. If it fails, want to to propogate the reason to the user.
  if (!success)
    rb_sys_fail("get_peername failed");
  // TODO: This should be done manually so we don't have to require Socket.
  VALUE ret = rb_funcall(rb_cSocket, Intern_unpack_sockaddr_in, 1, rb_str_new ((const char*)&s, sizeof(s)));
  // Return [host, port] rather than [port, host]
  return rb_ary_reverse(ret);
}

static VALUE conn_get_sockname(VALUE conn)
{
  EventableDescriptor *ed = ensure_connection(conn, "Connection#get_sockname");
  struct sockaddr s;
  bool success = ed->GetSockname(&s);
  if (!success)
    rb_sys_fail("get_socketname failed");
  // TODO: This should be done manually so we don't have to require Socket.
  VALUE ret = rb_funcall(rb_cSocket, Intern_unpack_sockaddr_in, 1, rb_str_new ((const char*)&s, sizeof(s)));
  // Return [host, port] rather than [port, host]
  return rb_ary_reverse(ret);
}

extern "C" void Init_rubyeventmachine()
{
  Intern_run_deferred_callbacks = rb_intern("run_deferred_callbacks");
  Intern_at_timers = rb_intern("@timers");
  Intern_reactor = rb_intern("@reactor");
  Intern_call = rb_intern("call");
  Intern_connection_completed = rb_intern("connection_completed");
  Intern_receive_data = rb_intern("receive_data");
  Intern_initialize = rb_intern("initialize");
  Intern_unbind = rb_intern("unbind");
  Intern_notify_readable = rb_intern("notify_readable");
  Intern_notify_writable = rb_intern("notify_writable");
  Intern_ssl_handshake_completed = rb_intern("ssl_handshake_completed");
  Intern_proxy_target_unbound = rb_intern("proxy_target_unbound");
  Intern_ssl_verify_peer = rb_intern("ssl_verify_peer");
  Intern_new = rb_intern("new");
  Intern_unpack_sockaddr_in = rb_intern("unpack_sockaddr_in");

  rb_require("socket");
  rb_cSocket = rb_const_get(rb_cObject, rb_intern("Socket"));

  EmModule = rb_define_module ("EventMachine");
  EmReactor = rb_define_class_under (EmModule, "Reactor", rb_cObject);
  EmTCPServer = rb_define_class_under (EmModule, "TCPServer", rb_cObject);
	EmConnection = rb_define_class_under (EmModule, "Connection", rb_cObject);
  EmIPConnection = rb_define_class_under (EmModule, "IPConnection", EmConnection);
	EmTCPConnection = rb_define_class_under (EmModule, "TCPConnection", EmIPConnection);
	EmUDPConnection = rb_define_class_under (EmModule, "UDPConnection", EmIPConnection);

  rb_define_alloc_func(EmReactor, reactor_alloc);

  rb_define_method(EmReactor, "signal_loopbreak", (VALUE(*)(...))reactor_signal_loopbreak, 0);
  rb_define_method(EmReactor, "run_machine", (VALUE(*)(...))reactor_run, 0);
  rb_define_method(EmReactor, "stop", (VALUE(*)(...))reactor_stop, 0);
  rb_define_method(EmReactor, "release", (VALUE(*)(...))reactor_release, 0);
  rb_define_method(EmReactor, "add_oneshot_timer", (VALUE(*)(...))reactor_add_timer, 1);
  rb_define_method(EmReactor, "connect", (VALUE(*)(...))reactor_connect_tcp, -1);
  rb_define_method(EmReactor, "start_server", (VALUE(*)(...))reactor_start_tcp_server, -1);

  rb_define_method(EmTCPServer, "get_sockname", (VALUE(*)(...))conn_get_sockname, 0);
  rb_define_method(EmTCPServer, "stop", (VALUE(*)(...))conn_close_connection, -1);

  rb_define_method(EmConnection, "send_data", (VALUE(*)(...))conn_send_data, 1);
  rb_define_method(EmConnection, "close_connection", (VALUE(*)(...))conn_close_connection, -1);
  rb_define_method(EmConnection, "proxy_incoming_to", (VALUE(*)(...))conn_proxy_incoming_to, 1);
  rb_define_method(EmConnection, "stop_proxy", (VALUE(*)(...))conn_stop_proxy, 0);

  rb_define_method(EmIPConnection, "get_peername", (VALUE(*)(...))conn_get_peername, 0);
  rb_define_method(EmIPConnection, "get_sockname", (VALUE(*)(...))conn_get_sockname, 0);
}
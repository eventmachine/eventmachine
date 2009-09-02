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

static VALUE EmModule;
static VALUE EmConnection;
static VALUE EmReactor;

static VALUE Intern_run_deferred_callbacks;
static VALUE Intern_at_timers;
static VALUE Intern_call;
static VALUE Intern_connection_completed;
static VALUE Intern_reactor;
static VALUE Intern_receive_data;
static VALUE Intern_initialize;
static VALUE Intern_unbind;

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
}

void evma_free(VALUE reactor)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  delete em;
}

void evma_mark(EventMachine_t *reactor)
{
  unsigned int i;
  vector<EventableDescriptor*> desc = reactor->GetDescriptors();
  vector<EventableDescriptor*> desc2 = reactor->GetNewDescriptors();

  for (i=0; i < desc.size(); i++) {
    rb_gc_mark(desc[i]->GetBinding());
  }
  for (i=0; i < desc2.size(); i++) {
    rb_gc_mark(desc2[i]->GetBinding());
  }
}

static VALUE evma_reactor_alloc(VALUE klass)
{
  EventMachine_t *em = new EventMachine_t(event_callback);
  VALUE emobj = Data_Wrap_Struct(klass, evma_mark, evma_free, em);
  em->SetBinding(emobj);
  return emobj;
}

static VALUE evma_signal_loopbreak(VALUE reactor)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  em->SignalLoopBreaker();
  return Qnil;
}

static VALUE evma_run_machine(VALUE reactor)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  em->Run();
  return Qnil;
}

static VALUE evma_stop_machine(VALUE reactor)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  em->ScheduleHalt();
  rb_funcall(reactor, rb_intern("machine_stopped"), 0);
  return Qnil;
}

static VALUE evma_add_timer(VALUE reactor, VALUE interval)
{
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  return ULONG2NUM(em->InstallOneshotTimer(FIX2INT(interval)));
}

static VALUE evma_connect_tcp(int argc, VALUE *argv, VALUE reactor)
{
  VALUE server = argv[0];
  VALUE port = argv[1];
  VALUE handler = argv[2];
  EventMachine_t *em = (EventMachine_t*) DATA_PTR(reactor);
  ConnectionDescriptor *cd = em->ConnectToServer(NULL, 0, StringValuePtr(server), FIX2INT(port));
  
  // This stuff should be moved into another function for generic handler instantiation
  if (cd) {
    VALUE real_handler;
    if (RTEST(handler)) {
	    if (rb_obj_is_kind_of(handler, rb_cClass) == Qtrue) {
        if (!rb_class_inherited_p(handler, EmConnection))
          rb_raise(rb_eArgError, "must provide module or subclass of EventMachine::Connection");
        real_handler = handler;
      }
      else {
        VALUE anon_klass = rb_funcall(rb_cClass, rb_intern("new"), 1, EmConnection);
        rb_include_module(anon_klass, handler);
        real_handler = anon_klass;
      }
    }
    else {
      real_handler = EmConnection;
    }

    VALUE cdobj = Data_Wrap_Struct(real_handler, NULL, NULL, cd);
    rb_ivar_set(cdobj, Intern_reactor, cd->GetReactor()->GetBinding());

    // Pass extra arguments to the handler's initialize
    if (argc > 3) {
      int newargc = argc - 3;
      VALUE newargv[newargc];
      for (int i=0; i < newargc; i++) {
        newargv[i] = argv[i+3];
      }
      rb_funcall2(cdobj, Intern_initialize, newargc, newargv);
    }

    cd->SetBinding(cdobj);
    return cdobj;
  }
  return Qnil;
}

static VALUE evma_tcp_send_data(VALUE connection, VALUE data)
{
  ConnectionDescriptor *cd = (ConnectionDescriptor*) DATA_PTR(connection);
  return INT2NUM(cd->SendOutboundData(RSTRING_PTR(data), RSTRING_LEN(data)));
}

static VALUE evma_close_connection(int argc, VALUE *argv, VALUE conn)
{
  VALUE after_writing = Qfalse;
  rb_scan_args(argc, argv, "01", &after_writing);
  EventableDescriptor *ed = (EventableDescriptor*) DATA_PTR(conn);
  ed->ScheduleClose((after_writing == Qtrue) ? true : false);
  return Qnil;
}

extern "C" void Init_rubyeventmachine()
{
  EmModule = rb_define_module ("EventMachine");
  EmConnection = rb_define_class_under (EmModule, "Connection", rb_cObject);
  EmReactor = rb_define_class_under (EmModule, "Reactor", rb_cObject);

  Intern_run_deferred_callbacks = rb_intern("run_deferred_callbacks");
  Intern_at_timers = rb_intern("@timers");
  Intern_reactor = rb_intern("@reactor");
  Intern_call = rb_intern("call");
  Intern_connection_completed = rb_intern("connection_completed");
  Intern_receive_data = rb_intern("receive_data");
  Intern_initialize = rb_intern("initialize");
  Intern_unbind = rb_intern("unbind");

  rb_define_alloc_func(EmReactor, evma_reactor_alloc);

  rb_define_method(EmReactor, "signal_loopbreak", (VALUE(*)(...))evma_signal_loopbreak, 0);
  rb_define_method(EmReactor, "run_machine", (VALUE(*)(...))evma_run_machine, 0);
  rb_define_method(EmReactor, "stop", (VALUE(*)(...))evma_stop_machine, 0);
  rb_define_method(EmReactor, "add_oneshot_timer", (VALUE(*)(...))evma_add_timer, 1);
  rb_define_method(EmReactor, "connect", (VALUE(*)(...))evma_connect_tcp, -1);

  rb_define_method(EmConnection, "send_data", (VALUE(*)(...))evma_tcp_send_data, 1);
  rb_define_method(EmConnection, "close_connection", (VALUE(*)(...))evma_close_connection, -1);
}
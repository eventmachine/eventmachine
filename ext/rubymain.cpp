#include "project.h"
#include <ruby.h>
#include "em.h"
#include "ed.h"

static VALUE EmModule;
static VALUE EmConnection;
static VALUE EmReactor;

static VALUE Intern_run_deferred_callbacks;
static VALUE Intern_at_timers;
static VALUE Intern_call;

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

static void event_callback (const unsigned long a1, int a2, const char *a3, const unsigned long a4)
{
	if (a2 == EM_LOOPBREAK_SIGNAL) {
		evma_callback_loopbreak((VALUE) a1);
	}
	else if (a2 == EM_TIMER_FIRED) {
		evma_callback_timer((VALUE) a1, a4);
	}
}

void evma_free(VALUE self)
{
	EventMachine_t *em = (EventMachine_t*) DATA_PTR(self);
	delete em;
}

static VALUE evma_reactor_alloc(VALUE klass)
{
	EventMachine_t *em = new EventMachine_t(event_callback);
	VALUE emobj = Data_Wrap_Struct(klass, NULL, evma_free, em);
	em->SetBinding(emobj);
	return emobj;
}

static VALUE evma_signal_loopbreak(VALUE self)
{
	EventMachine_t *em = (EventMachine_t*) DATA_PTR(self);
	em->SignalLoopBreaker();
	return Qnil;
}

static VALUE evma_run_machine(VALUE self)
{
	EventMachine_t *em = (EventMachine_t*) DATA_PTR(self);
	em->Run();
	return Qnil;
}

static VALUE evma_stop_machine(VALUE self)
{
	EventMachine_t *em = (EventMachine_t*) DATA_PTR(self);
	em->ScheduleHalt();
	rb_funcall(self, rb_intern("machine_stopped"), 0);
	return Qnil;
}

static VALUE evma_add_timer(VALUE self, VALUE interval)
{
	EventMachine_t *em = (EventMachine_t*) DATA_PTR(self);
	return ULONG2NUM(em->InstallOneshotTimer(FIX2INT(interval)));
}

extern "C" void Init_rubyeventmachine()
{
	EmModule = rb_define_module ("EventMachine");
	EmConnection = rb_define_class_under (EmModule, "Connection", rb_cObject);
	EmReactor = rb_define_class_under (EmModule, "Reactor", rb_cObject);

	Intern_run_deferred_callbacks = rb_intern("run_deferred_callbacks");
	Intern_at_timers = rb_intern("@timers");
	Intern_call = rb_intern("call");

	rb_define_alloc_func(EmReactor, evma_reactor_alloc);

	rb_define_method(EmReactor, "signal_loopbreak", (VALUE(*)(...))evma_signal_loopbreak, 0);
	rb_define_method(EmReactor, "run_machine", (VALUE(*)(...))evma_run_machine, 0);
	rb_define_method(EmReactor, "stop", (VALUE(*)(...))evma_stop_machine, 0);
	rb_define_method(EmReactor, "add_oneshot_timer", (VALUE(*)(...))evma_add_timer, 1);
}
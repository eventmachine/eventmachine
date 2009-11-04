#include "ruby.h"

typedef struct em_data {
	char *data;
	unsigned long len;
} em_data;

typedef struct em_hook {
	VALUE arg;
	int enabled;
	union {
		void (*recv_func)(em_data unit, VALUE arg);
		em_data (*send_func)(int argc, VALUE *argv, VALUE arg);
	};
} em_hook;

static VALUE EmTestextModule;

static void hooked_recv_function(em_data unit, VALUE arg)
{
	rb_ivar_set(EmTestextModule, rb_intern("@recv_hook_called"), Qtrue);
	rb_ivar_set(EmTestextModule, rb_intern("@test_data"), rb_str_new2("zomg manipulated inbound dataz"));
	rb_ivar_set(EmTestextModule, rb_intern("@real_data"), rb_str_new(unit.data, unit.len));
	rb_funcall((VALUE)arg, rb_intern("close_connection"), 0);
}

em_data hooked_send_function(int argc, VALUE *argv, VALUE arg)
{
	rb_ivar_set(EmTestextModule, rb_intern("@send_hook_called"), Qtrue);
	char *str = strdup("zomg manipulated outbound dataz");
	em_data unit;
	unit.data = str;
	unit.len = strlen(str);
	return unit;
}

static VALUE em_send_hook(VALUE self, VALUE arg)
{
	VALUE Em = rb_const_get(rb_cObject, rb_intern("EventMachine"));
	VALUE EmHooks = rb_const_get(Em, rb_intern("Hooks"));
	VALUE hooksobj = rb_funcall(EmHooks, rb_intern("new"), 0);
	em_hook *hook = (em_hook*) DATA_PTR(hooksobj);
	hook->send_func = hooked_send_function;
	hook->enabled = 1;
	hook->arg = arg;
	return hooksobj;
}

static VALUE em_recv_hook(VALUE self, VALUE arg)
{
	VALUE Em = rb_const_get(rb_cObject, rb_intern("EventMachine"));
	VALUE EmHooks = rb_const_get(Em, rb_intern("Hooks"));
	VALUE hooksobj = rb_funcall(EmHooks, rb_intern("new"), 0);
	em_hook *hook = (em_hook*) DATA_PTR(hooksobj);
	hook->recv_func = hooked_recv_function;
	hook->enabled = 1;
	hook->arg = arg;
	return hooksobj;
}

void Init_emtestext()
{
	EmTestextModule = rb_define_module("EmTestext");
	rb_define_module_function(EmTestextModule, "em_send_hook", em_send_hook, 1);
	rb_define_module_function(EmTestextModule, "em_recv_hook", em_recv_hook, 1);	
}
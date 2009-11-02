#include "ruby.h"

typedef struct em_data {
	char *data;
	unsigned long len;
} em_data;

typedef struct em_hooks {
	VALUE recv_arg;
	VALUE send_arg;
	int recv_hook_enabled;
	void (*em_recv_data)(em_data unit, VALUE arg);
	em_data (*em_send_data)(int argc, VALUE *argv, VALUE arg);
} em_hooks;

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

static VALUE get_em_hooks(VALUE self, VALUE recv_arg, VALUE send_arg)
{
	VALUE Em = rb_const_get(rb_cObject, rb_intern("EventMachine"));
	VALUE EmHooks = rb_const_get(Em, rb_intern("Hooks"));
	VALUE hooksobj = rb_funcall(EmHooks, rb_intern("new"), 0);
	em_hooks *hooks = (em_hooks*) DATA_PTR(hooksobj);
	hooks->em_recv_data = hooked_recv_function;
	hooks->em_send_data = hooked_send_function;
	hooks->recv_hook_enabled = 1;
	hooks->send_arg = send_arg;
	hooks->recv_arg = recv_arg;
	return hooksobj;
}

void Init_emtestext()
{
	EmTestextModule = rb_define_module("EmTestext");
	rb_define_module_function(EmTestextModule, "get_em_hooks", get_em_hooks, 2);
}
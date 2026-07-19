/*
 * This file was copied and adapted from the Ruby/OpenSSL project.
 */
/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2000-2025 Ruby/OpenSSL Project Authors
 * Copyright (C) 2025 EventMachine project authors
 * All rights reserved.
 */
/*
 * This file is licensed under the same licence as Ruby.
 * (See the file 'COPYING-openssl'.)
 */
#include "em_ossl.h"
#include <stdarg.h> /* for ossl_raise */

#ifdef WITH_SSL

/*
 * Data Conversion
 */

/* adapted from stdlib openssl's ossl_str_new_i */
static VALUE em_ssl_str_new_i(VALUE size)
{
	return rb_str_new(NULL, (long)size);
}

/* adapted from stdlib openssl's ossl_str_new */
VALUE em_ssl_str_new(const char *ptr, long len, int *pstate)
{
	VALUE str;
	int state;

	str = rb_protect(em_ssl_str_new_i, len, &state);
	if (pstate)
		*pstate = state;
	if (state) {
		if (!pstate)
			rb_set_errinfo(Qnil);
		return Qnil;
	}
	if (ptr)
		memcpy(RSTRING_PTR(str), ptr, len);
	return str;
}

/*
 * main module
 */
VALUE mEmSsl;

#endif /* WITH_SSL */

void Init_em_ssl(void)
{
#ifdef WITH_SSL
	/*
	 * Init main module
	 */
	VALUE rb_mEM = rb_const_get(rb_cObject, rb_intern("EventMachine"));
	rb_global_variable(&mEmSsl);
	mEmSsl = rb_define_module_under (rb_mEM, "SSL");

	Init_em_ssl_x509();
#endif /* WITH_SSL */
}

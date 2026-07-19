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

/*
 * Verify callback stuff
 */
static VALUE Intern_ssl_verify_peer;

static VALUE em_ssl_x509stctx_new(X509_STORE_CTX *);

/*
 * Adapted from stdlib openssl's ossl_verify_cb_args
 *
 * NOTE: proc has been renamed to conn.  It should be an EM::Connection object.
 */
struct em_ssl_verify_cb_args {
	VALUE conn;
	VALUE preverify_ok;
	VALUE store_ctx;
};

/* Adapted from stdlib openssl's ossl_x509stctx_new_i */
static VALUE em_ssl_x509stctx_new_i(VALUE arg)
{
	return em_ssl_x509stctx_new((X509_STORE_CTX *)arg);
}

/*
 * NOTE: This has been significantly altered from openssl's call_verify_cb_proc.
 * It calls EM::Connection#ssl_verify_peer instead of Proc#call.
 */
static VALUE em_ssl_call_verify_peer(VALUE arg)
{
	struct em_ssl_verify_cb_args *args = (struct em_ssl_verify_cb_args *)arg;
	if (rb_obj_method_arity(args->conn, Intern_ssl_verify_peer) == 1) {
		// Backwards compatibility:
		VALUE cert = rb_funcall(args->store_ctx, rb_intern("current_cert"), 0);
		VALUE pem = rb_funcall(cert, rb_intern("to_pem"), 0);
		return rb_funcall(args->conn, Intern_ssl_verify_peer,
		                  1, pem);
	} else {
		return rb_funcall(args->conn, Intern_ssl_verify_peer,
		                  2, args->preverify_ok, args->store_ctx);
	}
}

/*
 * NOTE: proc has been renamed to conn.  It should be an EM::Connection object.
 */
int em_ssl_verify_cb_call(VALUE conn, int ok, X509_STORE_CTX *ctx)
{
	VALUE rctx, ret;
	struct em_ssl_verify_cb_args args;
	int state;

	if (NIL_P(conn))
		return ok;

	ret = Qfalse;
	rctx = rb_protect(em_ssl_x509stctx_new_i, (VALUE)ctx, &state);
	if (state) {
		rb_set_errinfo(Qnil);
		rb_warn("StoreContext initialization failure");
	}
	else {
		args.conn = conn;
		args.preverify_ok = ok ? Qtrue : Qfalse;
		args.store_ctx = rctx;
		ret = rb_protect(em_ssl_call_verify_peer, (VALUE)&args, &state);
		if (state) {
			rb_set_errinfo(Qnil);
			rb_warn("exception in verify_peer is ignored");
		}
		// RTYPEDDATA_DATA(rctx) = NULL; // rctx isn't RTYPEDDATA here
	}
	if (ret == Qtrue) {
		X509_STORE_CTX_set_error(ctx, X509_V_OK);
		ok = 1;
	}
	else {
		if (X509_STORE_CTX_get_error(ctx) == X509_V_OK)
			X509_STORE_CTX_set_error(ctx, X509_V_ERR_CERT_REJECTED);
		ok = 0;
	}

	return ok;
}


/*
 * Classes
 */
VALUE cEmSslX509StoreContext;

/*
 * Private functions
 */

/*
 * This has been altered significantly from ossl_x509stctx_new, in order to
 * simply copy the data into a EM::SSL::X509::StoreContext object.
 */
static VALUE em_ssl_x509stctx_new(X509_STORE_CTX *ctx)
{
	int   error_code   = X509_STORE_CTX_get_error(ctx);
	VALUE error        = INT2NUM(error_code);
	VALUE error_string = rb_str_new2(X509_verify_cert_error_string(error_code));
	VALUE error_depth  = INT2NUM(X509_STORE_CTX_get_error_depth(ctx));
	X509 *x509         = X509_STORE_CTX_get_current_cert(ctx);
	VALUE current_cert = em_ssl_x509_to_pem(x509);

	VALUE args[4] = { current_cert, error_depth, error, error_string, };
	return rb_class_new_instance(4, args, cEmSslX509StoreContext);
}

/*
 * INIT
 */
void Init_em_ssl_x509store(void)
{
	Intern_ssl_verify_peer = rb_intern ("ssl_verify_peer");
	cEmSslX509StoreContext = rb_define_class_under (mEmSslX509, "StoreContext", rb_cObject);
}

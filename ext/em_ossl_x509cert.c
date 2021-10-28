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
 * Adapted from stdlib openssl's ossl_x509_to_pem.
 *
 * Input is X509*, unlike ossl_x509_to_pem which is an instance method (so the
 * input is VALUE self).
 */
VALUE em_ssl_x509_to_pem(X509 *x509)
{
	BIO *out;
	VALUE str;

	out = BIO_new(BIO_s_mem());
	if (!out) rb_raise(rb_eRuntimeError, "%s", "EventMachine X509 cert error");

	if (!PEM_write_bio_X509(out, x509)) {
		BIO_free(out);
		rb_raise(rb_eRuntimeError, "%s", "EventMachine X509 cert error");
	}
	str = em_ssl_membio2str(out);

	return str;
}

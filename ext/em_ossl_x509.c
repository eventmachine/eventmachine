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

VALUE mEmSslX509;

void Init_em_ssl_x509(void)
{
	mEmSslX509 = rb_define_module_under (mEmSsl, "X509");

	Init_em_ssl_x509store();
}

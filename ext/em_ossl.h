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
#if !defined(_EM_OSSL_H_)
#define _EM_OSSL_H_

#ifdef WITH_SSL

/*#include RUBY_EXTCONF_H */

#include <assert.h>
#include <ruby.h>
#include <errno.h>
#include <ruby/io.h>
#include <ruby/thread.h>

#include <openssl/err.h>
#include <openssl/ssl.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Common Module
 */
extern VALUE mEmSsl;

/*
 * Data Conversion
 */
VALUE em_ssl_str_new(const char *, long, int *);

/*
 * Include all parts
 */
#include "em_ossl_bio.h"
#include "em_ossl_x509.h"

#endif /* WITH_SSL */

void Init_em_ssl(void);

#ifdef __cplusplus
}
#endif

#endif /* _EM_OSSL_H_ */

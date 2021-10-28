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

#if !defined(_EM_OSSL_X509_H_)
#define _EM_OSSL_X509_H_

/*
 * X509 main module
 */
extern VALUE mEmSslX509;

void Init_em_ssl_x509(void);

/*
 * X509Store and X509StoreContext
 */
extern VALUE cEmSslX509StoreContext;

void Init_em_ssl_x509store(void);

/*
 * Calls the verify callback Proc (the first parameter) with given pre-verify
 * result and the X509_STORE_CTX.
 */
int em_ssl_verify_cb_call(VALUE, int, X509_STORE_CTX *);

/*
 * Input is X509*, unlike ossl_x509_to_pem which is an instance method (so the
 * input is VALUE self).
 *
 * Also, since it's not an instance method, it's not static.
 */
VALUE em_ssl_x509_to_pem(X509 *x509);

#endif /* _EM_OSSL_X509_H_ */

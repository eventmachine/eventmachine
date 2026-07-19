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
#if !defined(_EM_OSSL_BIO_H_)
#define _EM_OSSL_BIO_H_

/* BIO *emssl_obj2bio(volatile VALUE *); */
VALUE em_ssl_membio2str(BIO*);

#endif

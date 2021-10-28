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

/* adapted from stdlib openssl's ossl_membio2str */
VALUE em_ssl_membio2str(BIO *bio)
{
	VALUE ret;
	int state;
	BUF_MEM *buf;

	BIO_get_mem_ptr(bio, &buf);
	ret = em_ssl_str_new(buf->data, buf->length, &state);
	BIO_free(bio);
	if (state)
		rb_jump_tag(state);

	return ret;
}

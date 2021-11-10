/*****************************************************************************

$Id$

File:     ssl.h
Date:     30Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/


#ifndef __SslBox__H_
#define __SslBox__H_

#include "page.h"
#include <openssl/ossl_typ.h>
#include <string>

#ifdef WITH_SSL

/******************
class SslContext_t
******************/

// "SSLContext < Struct" => em_ssl_ctx_t => SslContext_t => SSL_CTX
// This can definitely be simplified!

/* This struct, em_ssl_ctx, is used simply to pass values from the ruby API
 * layer into this C++ layer while keeping them seperated.  Is this useful?
 * Probably it's not.
 *
 * Proposal: the immediate SSL_CTX wrapping functionality should be moved into
 * a near-duplicate of stdlib's OpenSSL::SSL::SSLContext.  i.e. EM::SSL::Context
 * should use TypedData_Get_Struct around an SSL_CTX object.
 *
 * With that done, this C++ layer should probably just be deleted.  It won't be
 * doing much.  The other EM C++ code can reference the SSL_CTX object using the
 * openssl API, or (where necessary) use the ruby VALUE wrapper via
 * SSL_CTX_get_ex_data.
 *
 */
typedef struct em_ssl_ctx {
	int min_proto_version;
	int max_proto_version;
	unsigned long options;
	int verify_mode;
	bool verify_hostname;

	/* X509_STORE *cert_store; */
	bool cert_store;
	const char *ca_file;
	const char *ca_path;

	const char *cert;
	const char *cert_chain_file;
	const char *key;
	const char *private_key_file;
	const char *private_key_pass;
	int  private_key_pass_len;

	const char *ciphers;
	const char *ecdh_curve;
	const char *dhparam;
} em_ssl_ctx_t;

class SslContext_t
{
	public:
		SslContext_t (bool is_server, const em_ssl_ctx_t *context);
		virtual ~SslContext_t();
		bool bVerifyHostname;

	private:
		static bool bLibraryInitialized;
		static X509_STORE* bDefaultX509Store;

	private:
		bool bIsServer;
		SSL_CTX *pCtx;

		EVP_PKEY *PrivateKey;
		X509 *Certificate;

	friend class SslBox_t;
};


/**************
class SslBox_t
**************/

#define SSLBOX_INPUT_CHUNKSIZE 2019
#define SSLBOX_OUTPUT_CHUNKSIZE 2048
#define SSLBOX_WRITE_BUFFER_SIZE 8192 // (SSLBOX_OUTPUT_CHUNKSIZE * 4)

class SslBox_t
{
	public:
		SslBox_t (
				bool is_server,
				const std::string &snihostname,
				const SslContext_t *context,
				const uintptr_t binding);
		virtual ~SslBox_t();

		const std::string SniHostname;
		int PutPlaintext (const char*, int);
		int GetPlaintext (char*, int);

		bool PutCiphertext (const char*, int);
		bool CanGetCiphertext();
		int GetCiphertext (char*, int);
		bool IsHandshakeCompleted() {return bHandshakeCompleted;}

		int VerifyPeer(bool, X509_STORE_CTX *);

		X509 *GetPeerCert();
		int GetCipherBits();
		const char *GetCipherName();
		const char *GetCipherProtocol();
		const char *GetSNIHostname();

		void Shutdown();

	protected:
		const SslContext_t *Context;

		bool bIsServer;
		bool bHandshakeCompleted;
		SSL *pSSL;
		BIO *pbioRead;
		BIO *pbioWrite;

		PageList OutboundQ;
};

extern "C" int em_ossl_ssl_verify_callback(int, X509_STORE_CTX*);

#endif // WITH_SSL


#endif // __SslBox__H_


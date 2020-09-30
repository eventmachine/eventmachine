/*****************************************************************************

$Id$

File:     ssl.cpp
Date:     30Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/


#ifdef WITH_SSL

#include "project.h"


bool SslContext_t::bLibraryInitialized = false;



static void InitializeDefaultCredentials();
static EVP_PKEY *DefaultPrivateKey = NULL;
static X509 *DefaultCertificate = NULL;

static char PrivateMaterials[] = {
"-----BEGIN RSA PRIVATE KEY-----\n"
"MIIEpAIBAAKCAQEA25ZTHopLfMKYeVwZoWtDwBd1RqCJhIL7wgDy/05jzIYm8JFf\n"
"xwFI+pau/3mLVHYPrl9rXeM5ZBONeLwewDJAsIYVtyZ8O9pICK6uz4sogfwST8Uc\n"
"/sumdd/mq2vIw4zEGjcaXdmMZYrJOxlvx32Fsrc5M6iNIMQYFnLPU3KsJhvOAZiM\n"
"6jEn2wIszhq5X/5HupaOuCaZqCxOtaXaWguJF4SGFW6tBMxaY4ryiLyUwC0EGPoH\n"
"C2f34DxeXpRQ9TNS3H//L90wTok6slrqZQ/4zXU64+0pd5q35FqnS7gU7H6SQ9yj\n"
"TWPPe/gNTVPWoQd9SJJmB7Q1BYukcfDnh69NBwIDAQABAoIBABErG6yTm3tRq6Ix\n"
"dT+Np2ppax3uh1H4+74bXORhOKRRCNJeS2K/0vjktyH6Ws5rvKYhh797eI0+ih0a\n"
"eD0GsNAca646MBRt6JvlLH3Fn5EqKDRccPvq6ETnEJ3ue2/unZZ/IGyeCcAWrc0V\n"
"HAw44C8s7CgB0abyLf/zUgpwOM1x0etDpIiMBEUxpV+aG5wsAAcj3Q0rkxUhfIgS\n"
"QB1eWGgN/irfaUqPOwXZ85cWBVQlck1eCKeWJJkHffcqfqfcuy2d8W5PN0DeD3kS\n"
"QW/+hXnxSU39/DymsomsjKnrB4IwW6lVGxRXyVhMiz3bxmEmRK7YdkCzsDO8VWBa\n"
"bcctQgECgYEA/jIzxNwmmhwAgDNhnjgMi55zyEQdAdvNz/2VYbE2b5ImudWc53md\n"
"UFCVDS4aTYN0uIkGI/bLuAydw6I766tnmu8WXE2k4tAahBRRrsXGahY7Aom1FjfQ\n"
"kvMjgnGTunO+r1bGJ+KbXi6x7yt1gucp4qh4msrry5D1pUva2SA7CsECgYEA3SU/\n"
"nuCmMPVEsYnDIzxZC0qBSrLB1h1HB7vsFyecQV6tOYVJRSU8v+DARAc38Mveivja\n"
"mw5GgdEEYAx1roNhpjlMG2B9K7dShLMiFonn9c/euq/JpmcDI+yqIyFNQAgLVcB7\n"
"+3HVjEbI1qsCr87RH0QdiTsWTk4wa6EzIIJ7MccCgYBWgYEqqn0cjxEAj/vVm19x\n"
"mE/wxHVWr5XgBX1zzJoo6ATz0yVdhP6rWXEQFjNvU6BCOKd1T8TOcsSx0iEwN5m/\n"
"mUPzz5ygb4/GiR+vKbE3Yy9b0r9ku0Po7oOUHdDXcBJhm1c+NZkIOT3mldSc4sxX\n"
"TVwV2Z7bHQ7r3N+yaoyNQQKBgQCC2B8kadbq8LOMN+51Uqd8vsBw6gM2JGx6bv3p\n"
"VU5mfxYPCoWnm7it7tTTa1H17ynlIAh35aJh/MGR8s1OS/3i09Pr/tMQoo74ZOSu\n"
"YToVfsBRxOCSzDBXeRfRYUrLr/bE7fZtd5TaQqdiHByi2MNytGKlZ4hzHGAZzm7p\n"
"tUoe0QKBgQD3/KR7XFplvrceBMi2fqdO0UWP6vqOfKd315TlvntTcn3cdgab4mKk\n"
"UOh3S4lyrW0uU/LQh91+ulGbJejdjiCphj3PMpd8MXzcUVd4WQmPMVOP2R+86rGh\n"
"1EsiZHUMNRsCzwJtPDN48OmELxx9MikVgecj7OLvi4uelDSgVkFqdA==\n"
"-----END RSA PRIVATE KEY-----\n"
"-----BEGIN CERTIFICATE-----\n"
"MIIDajCCAtOgAwIBAgIJANm4W/Tzs+s+MA0GCSqGSIb3DQEBCwUAMIGqMQswCQYD\n"
"VQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxETAPBgNVBAcTCE5ldyBZb3JrMRYw\n"
"FAYDVQQKEw1TdGVhbWhlYXQubmV0MRQwEgYDVQQLEwtFbmdpbmVlcmluZzEdMBsG\n"
"A1UEAxMUb3BlbmNhLnN0ZWFtaGVhdC5uZXQxKDAmBgkqhkiG9w0BCQEWGWVuZ2lu\n"
"ZWVyaW5nQHN0ZWFtaGVhdC5uZXQwHhcNMjAwOTAxMDAwMDAwWhcNMzAwOTAxMDAw\n"
"MDAwWjCBqjELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5ldyBZb3JrMREwDwYDVQQH\n"
"EwhOZXcgWW9yazEWMBQGA1UEChMNU3RlYW1oZWF0Lm5ldDEUMBIGA1UECxMLRW5n\n"
"aW5lZXJpbmcxHTAbBgNVBAMTFG9wZW5jYS5zdGVhbWhlYXQubmV0MSgwJgYJKoZI\n"
"hvcNAQkBFhllbmdpbmVlcmluZ0BzdGVhbWhlYXQubmV0MIIBIjANBgkqhkiG9w0B\n"
"AQEFAAOCAQ8AMIIBCgKCAQEA25ZTHopLfMKYeVwZoWtDwBd1RqCJhIL7wgDy/05j\n"
"zIYm8JFfxwFI+pau/3mLVHYPrl9rXeM5ZBONeLwewDJAsIYVtyZ8O9pICK6uz4so\n"
"gfwST8Uc/sumdd/mq2vIw4zEGjcaXdmMZYrJOxlvx32Fsrc5M6iNIMQYFnLPU3Ks\n"
"JhvOAZiM6jEn2wIszhq5X/5HupaOuCaZqCxOtaXaWguJF4SGFW6tBMxaY4ryiLyU\n"
"wC0EGPoHC2f34DxeXpRQ9TNS3H//L90wTok6slrqZQ/4zXU64+0pd5q35FqnS7gU\n"
"7H6SQ9yjTWPPe/gNTVPWoQd9SJJmB7Q1BYukcfDnh69NBwIDAQABoxIwEDAOBgNV\n"
"HQ8BAf8EBAMCBLAwDQYJKoZIhvcNAQELBQADgYEAc4mWHK3HHAwWXIsJztUOCEaT\n"
"yDpzqt5nnDqg5Q3/1HhiM4wsWoam9ixTcZk25+5xcMsvuSoDvzAJzyd5wpBkOq/z\n"
"UeWxZmLYOzOghrT62TLJVxAqh0AdEP8jMWOAeWrrOXnXx8AvG1+R8n4Rf5/koSa8\n"
"wJrrW4j7WAEsY5kG4hU=\n"
"-----END CERTIFICATE-----\n"};

/* These private materials were made with:
 * openssl req -new -x509 -keyout cakey.pem -out cacert.pem -nodes -days 6500
 * TODO: We need a full-blown capability to work with user-supplied
 * keypairs and properly-signed certificates.
 */


/*****************
builtin_passwd_cb
*****************/

extern "C" int builtin_passwd_cb (char *buf UNUSED, int bufsize UNUSED, int rwflag UNUSED, void *userdata UNUSED)
{
	strcpy (buf, "kittycat");
	return 8;
}

/****************************
InitializeDefaultCredentials
****************************/

static void InitializeDefaultCredentials()
{
	BIO *bio = BIO_new_mem_buf (PrivateMaterials, -1);
	assert (bio);

	if (DefaultPrivateKey) {
		// we may come here in a restart.
		EVP_PKEY_free (DefaultPrivateKey);
		DefaultPrivateKey = NULL;
	}
	PEM_read_bio_PrivateKey (bio, &DefaultPrivateKey, builtin_passwd_cb, 0);

	if (DefaultCertificate) {
		// we may come here in a restart.
		X509_free (DefaultCertificate);
		DefaultCertificate = NULL;
	}
	PEM_read_bio_X509 (bio, &DefaultCertificate, NULL, 0);

	BIO_free (bio);
}



/**************************
SslContext_t::SslContext_t
**************************/

SslContext_t::SslContext_t (bool is_server, const std::string &privkeyfile, const std::string &certchainfile, const std::string &cipherlist, const std::string &ecdh_curve, const std::string &dhparam, int ssl_version) :
	bIsServer (is_server),
	pCtx (NULL),
	PrivateKey (NULL),
	Certificate (NULL)
{
	/* TODO: the usage of the specified private-key and cert-chain filenames only applies to
	 * client-side connections at this point. Server connections currently use the default materials.
	 * That needs to be fixed asap.
	 * Also, in this implementation, server-side connections use statically defined X-509 defaults.
	 * One thing I'm really not clear on is whether or not you have to explicitly free X509 and EVP_PKEY
	 * objects when we call our destructor, or whether just calling SSL_CTX_free is enough.
	 */

	if (!bLibraryInitialized) {
		bLibraryInitialized = true;
		SSL_library_init();
		OpenSSL_add_ssl_algorithms();
		OpenSSL_add_all_algorithms();
		SSL_load_error_strings();
		ERR_load_crypto_strings();

		InitializeDefaultCredentials();
	}
	#ifdef HAVE_TLS_SERVER_METHOD
	pCtx = SSL_CTX_new (bIsServer ? TLS_server_method() : TLS_client_method());
	#else
	pCtx = SSL_CTX_new (bIsServer ? SSLv23_server_method() : SSLv23_client_method());
	#endif
	if (!pCtx)
		throw std::runtime_error ("no SSL context");

	SSL_CTX_set_options (pCtx, SSL_OP_ALL);

	#ifdef SSL_CTRL_CLEAR_OPTIONS
	SSL_CTX_clear_options (pCtx, SSL_OP_NO_SSLv2|SSL_OP_NO_SSLv3|SSL_OP_NO_TLSv1);
	# ifdef SSL_OP_NO_TLSv1_1
	SSL_CTX_clear_options (pCtx, SSL_OP_NO_TLSv1_1);
	# endif
	# ifdef SSL_OP_NO_TLSv1_2
	SSL_CTX_clear_options (pCtx, SSL_OP_NO_TLSv1_2);
	# endif
	#endif

	if (!(ssl_version & EM_PROTO_SSLv2))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_SSLv2);

	if (!(ssl_version & EM_PROTO_SSLv3))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_SSLv3);

	if (!(ssl_version & EM_PROTO_TLSv1))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_TLSv1);

	#ifdef SSL_OP_NO_TLSv1_1
	if (!(ssl_version & EM_PROTO_TLSv1_1))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_TLSv1_1);
	#endif

	#ifdef SSL_OP_NO_TLSv1_2
	if (!(ssl_version & EM_PROTO_TLSv1_2))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_TLSv1_2);
	#endif

	#ifdef SSL_OP_NO_TLSv1_3
	if (!(ssl_version & EM_PROTO_TLSv1_3))
		SSL_CTX_set_options (pCtx, SSL_OP_NO_TLSv1_3);
	#endif

	#ifdef SSL_MODE_RELEASE_BUFFERS
	SSL_CTX_set_mode (pCtx, SSL_MODE_RELEASE_BUFFERS);
	#endif

	if (bIsServer) {

		// The SSL_CTX calls here do NOT allocate memory.
		int e;
		if (privkeyfile.length() > 0)
			e = SSL_CTX_use_PrivateKey_file (pCtx, privkeyfile.c_str(), SSL_FILETYPE_PEM);
		else
			e = SSL_CTX_use_PrivateKey (pCtx, DefaultPrivateKey);
		if (e <= 0) ERR_print_errors_fp(stderr);
		assert (e > 0);

		if (certchainfile.length() > 0)
			e = SSL_CTX_use_certificate_chain_file (pCtx, certchainfile.c_str());
		else
			e = SSL_CTX_use_certificate (pCtx, DefaultCertificate);
		if (e <= 0) ERR_print_errors_fp(stderr);
		assert (e > 0);

		if (dhparam.length() > 0) {
			DH   *dh;
			BIO  *bio;

			bio = BIO_new_file(dhparam.c_str(), "r");
			if (bio == NULL) {
				char buf [500];
				snprintf (buf, sizeof(buf)-1, "dhparam: BIO_new_file(%s) failed", dhparam.c_str());
				throw std::runtime_error (buf);
			}

			dh = PEM_read_bio_DHparams(bio, NULL, NULL, NULL);

			if (dh == NULL) {
				BIO_free(bio);
				char buf [500];
				snprintf (buf, sizeof(buf)-1, "dhparam: PEM_read_bio_DHparams(%s) failed", dhparam.c_str());
				throw std::runtime_error (buf);
			}

			SSL_CTX_set_tmp_dh(pCtx, dh);

			DH_free(dh);
			BIO_free(bio);
		}

		if (ecdh_curve.length() > 0) {
			#if OPENSSL_VERSION_NUMBER >= 0x0090800fL && !defined(OPENSSL_NO_ECDH)
				int      nid;
				EC_KEY  *ecdh;

				nid = OBJ_sn2nid((const char *) ecdh_curve.c_str());
				if (nid == 0) {
					char buf [200];
					snprintf (buf, sizeof(buf)-1, "ecdh_curve: Unknown curve name: %s", ecdh_curve.c_str());
					throw std::runtime_error (buf);
				}

				ecdh = EC_KEY_new_by_curve_name(nid);
				if (ecdh == NULL) {
					char buf [200];
					snprintf (buf, sizeof(buf)-1, "ecdh_curve: Unable to create: %s", ecdh_curve.c_str());
					throw std::runtime_error (buf);
				}

				SSL_CTX_set_options(pCtx, SSL_OP_SINGLE_ECDH_USE);

				SSL_CTX_set_tmp_ecdh(pCtx, ecdh);

				EC_KEY_free(ecdh);
			#else
				throw std::runtime_error ("No openssl ECDH support");
			#endif
		}
	}

	if (cipherlist.length() > 0)
		SSL_CTX_set_cipher_list (pCtx, cipherlist.c_str());
	else
		SSL_CTX_set_cipher_list (pCtx, "ALL:!ADH:!LOW:!EXP:!DES-CBC3-SHA:@STRENGTH");

	if (bIsServer) {
		SSL_CTX_sess_set_cache_size (pCtx, 128);
		SSL_CTX_set_session_id_context (pCtx, (unsigned char*)"eventmachine", 12);
	}
	else {
		int e;
		if (privkeyfile.length() > 0) {
			e = SSL_CTX_use_PrivateKey_file (pCtx, privkeyfile.c_str(), SSL_FILETYPE_PEM);
			if (e <= 0) ERR_print_errors_fp(stderr);
			assert (e > 0);
		}
		if (certchainfile.length() > 0) {
			e = SSL_CTX_use_certificate_chain_file (pCtx, certchainfile.c_str());
			if (e <= 0) ERR_print_errors_fp(stderr);
			assert (e > 0);
		}
	}
}



/***************************
SslContext_t::~SslContext_t
***************************/

SslContext_t::~SslContext_t()
{
	if (pCtx)
		SSL_CTX_free (pCtx);
	if (PrivateKey)
		EVP_PKEY_free (PrivateKey);
	if (Certificate)
		X509_free (Certificate);
}



/******************
SslBox_t::SslBox_t
******************/

SslBox_t::SslBox_t (bool is_server, const std::string &privkeyfile, const std::string &certchainfile, bool verify_peer, bool fail_if_no_peer_cert, const std::string &snihostname, const std::string &cipherlist, const std::string &ecdh_curve, const std::string &dhparam, int ssl_version, const uintptr_t binding):
	bIsServer (is_server),
	bHandshakeCompleted (false),
	bVerifyPeer (verify_peer),
	bFailIfNoPeerCert (fail_if_no_peer_cert),
	pSSL (NULL),
	pbioRead (NULL),
	pbioWrite (NULL)
{
	/* TODO someday: make it possible to re-use SSL contexts so we don't have to create
	 * a new one every time we come here.
	 */

	Context = new SslContext_t (bIsServer, privkeyfile, certchainfile, cipherlist, ecdh_curve, dhparam, ssl_version);
	assert (Context);

	pbioRead = BIO_new (BIO_s_mem());
	assert (pbioRead);

	pbioWrite = BIO_new (BIO_s_mem());
	assert (pbioWrite);

	pSSL = SSL_new (Context->pCtx);
	assert (pSSL);

	if (snihostname.length() > 0) {
		SSL_set_tlsext_host_name (pSSL, snihostname.c_str());
	}

	SSL_set_bio (pSSL, pbioRead, pbioWrite);

	// Store a pointer to the binding signature in the SSL object so we can retrieve it later
	SSL_set_ex_data(pSSL, 0, (void*) binding);

	if (bVerifyPeer) {
		int mode = SSL_VERIFY_PEER | SSL_VERIFY_CLIENT_ONCE;
		if (bFailIfNoPeerCert)
			mode = mode | SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
		SSL_set_verify(pSSL, mode, ssl_verify_wrapper);
	}

	if (!bIsServer) {
		int e = SSL_connect (pSSL);
		if (e != 1)
			ERR_print_errors_fp(stderr);
	}
}



/*******************
SslBox_t::~SslBox_t
*******************/

SslBox_t::~SslBox_t()
{
	// Freeing pSSL will also free the associated BIOs, so DON'T free them separately.
	if (pSSL) {
		if (SSL_get_shutdown (pSSL) & SSL_RECEIVED_SHUTDOWN)
			SSL_shutdown (pSSL);
		else
			SSL_clear (pSSL);
		SSL_free (pSSL);
	}

	delete Context;
}



/***********************
SslBox_t::PutCiphertext
***********************/

bool SslBox_t::PutCiphertext (const char *buf, int bufsize)
{
	assert (buf && (bufsize > 0));

	assert (pbioRead);
	int n = BIO_write (pbioRead, buf, bufsize);

	return (n == bufsize) ? true : false;
}


/**********************
SslBox_t::GetPlaintext
**********************/

int SslBox_t::GetPlaintext (char *buf, int bufsize)
{
	if (!SSL_is_init_finished (pSSL)) {
		int e = bIsServer ? SSL_accept (pSSL) : SSL_connect (pSSL);
		if (e != 1) {
			int er = SSL_get_error (pSSL, e);
			if (er != SSL_ERROR_WANT_READ) {
				ERR_print_errors_fp(stderr);
				// Return -1 for a nonfatal error, -2 for an error that should force the connection down.
				return (er == SSL_ERROR_SSL) ? (-2) : (-1);
			}
			else
				return 0;
		}
		bHandshakeCompleted = true;
		// If handshake finished, FALL THROUGH and return the available plaintext.
	}

	if (!SSL_is_init_finished (pSSL)) {
		// We can get here if a browser abandons a handshake.
		// The user can see a warning dialog and abort the connection.
		//cerr << "<SSL_incomp>";
		return 0;
	}

	//cerr << "CIPH: " << SSL_get_cipher (pSSL) << endl;

	int n = SSL_read (pSSL, buf, bufsize);
	if (n >= 0) {
		return n;
	}
	else {
		if (SSL_get_error (pSSL, n) == SSL_ERROR_WANT_READ) {
			return 0;
		}
		else {
			return -1;
		}
	}

	return 0;
}



/**************************
SslBox_t::CanGetCiphertext
**************************/

bool SslBox_t::CanGetCiphertext()
{
	assert (pbioWrite);
	return BIO_pending (pbioWrite) ? true : false;
}



/***********************
SslBox_t::GetCiphertext
***********************/

int SslBox_t::GetCiphertext (char *buf, int bufsize)
{
	assert (pbioWrite);
	assert (buf && (bufsize > 0));

	return BIO_read (pbioWrite, buf, bufsize);
}



/**********************
SslBox_t::PutPlaintext
**********************/

int SslBox_t::PutPlaintext (const char *buf, int bufsize)
{
	// The caller will interpret the return value as the number of bytes written.
	// WARNING WARNING WARNING, are there any situations in which a 0 or -1 return
	// from SSL_write means we should immediately retry? The socket-machine loop
	// will probably wait for a time-out cycle (perhaps a second) before re-trying.
	// THIS WOULD CAUSE A PERCEPTIBLE DELAY!

	/* We internally queue any outbound plaintext that can't be dispatched
	 * because we're in the middle of a handshake or something.
	 * When we get called, try to send any queued data first, and then
	 * send the caller's data (or queue it). We may get called with no outbound
	 * data, which means we try to send the outbound queue and that's all.
	 *
	 * Return >0 if we wrote any data, 0 if we didn't, and <0 for a fatal error.
	 * Note that if we return 0, the connection is still considered live
	 * and we are signalling that we have accepted the outbound data (if any).
	 */

	OutboundQ.Push (buf, bufsize);

	if (!SSL_is_init_finished (pSSL))
		return 0;

	bool fatal = false;
	bool did_work = false;
	int pending = BIO_pending(pbioWrite);

	while (OutboundQ.HasPages() && pending < SSLBOX_WRITE_BUFFER_SIZE) {
		const char *page;
		int length;
		OutboundQ.Front (&page, &length);
		assert (page && (length > 0));
		int n = SSL_write (pSSL, page, length);
		pending = BIO_pending(pbioWrite);

		if (n > 0) {
			did_work = true;
			OutboundQ.PopFront();
		}
		else {
			int er = SSL_get_error (pSSL, n);
			if ((er != SSL_ERROR_WANT_READ) && (er != SSL_ERROR_WANT_WRITE))
				fatal = true;
			break;
		}
	}


	if (did_work)
		return 1;
	else if (fatal)
		return -1;
	else
		return 0;
}

/**********************
SslBox_t::GetPeerCert
**********************/

X509 *SslBox_t::GetPeerCert()
{
	X509 *cert = NULL;

	if (pSSL)
		cert = SSL_get_peer_certificate(pSSL);

	return cert;
}

/**********************
SslBox_t::GetCipherBits
**********************/

int SslBox_t::GetCipherBits()
{
	int bits = -1;
	if (pSSL)
		SSL_get_cipher_bits(pSSL, &bits);
	return bits;
}

/**********************
SslBox_t::GetCipherName
**********************/

const char *SslBox_t::GetCipherName()
{
	if (pSSL)
		return SSL_get_cipher_name(pSSL);
	return NULL;
}

/**********************
SslBox_t::GetCipherProtocol
**********************/

const char *SslBox_t::GetCipherProtocol()
{
	if (pSSL)
		return SSL_get_cipher_version(pSSL);
	return NULL;
}

/**********************
SslBox_t::GetSNIHostname
**********************/

const char *SslBox_t::GetSNIHostname()
{
	#ifdef TLSEXT_NAMETYPE_host_name
	if (pSSL)
		return SSL_get_servername (pSSL, TLSEXT_NAMETYPE_host_name);
	#endif
	return NULL;
}

/******************
ssl_verify_wrapper
*******************/

extern "C" int ssl_verify_wrapper(int preverify_ok UNUSED, X509_STORE_CTX *ctx)
{
	uintptr_t binding;
	X509 *cert;
	SSL *ssl;
	BUF_MEM *buf;
	BIO *out;
	int result;

	cert = X509_STORE_CTX_get_current_cert(ctx);
	ssl = (SSL*) X509_STORE_CTX_get_ex_data(ctx, SSL_get_ex_data_X509_STORE_CTX_idx());
	binding = (uintptr_t) SSL_get_ex_data(ssl, 0);

	out = BIO_new(BIO_s_mem());
	PEM_write_bio_X509(out, cert);
	BIO_write(out, "\0", 1);
	BIO_get_mem_ptr(out, &buf);

	ConnectionDescriptor *cd = dynamic_cast <ConnectionDescriptor*> (Bindable_t::GetObject(binding));
	result = (cd->VerifySslPeer(buf->data) == true ? 1 : 0);
	BIO_free(out);

	return result;
}

#endif // WITH_SSL


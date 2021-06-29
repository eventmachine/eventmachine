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
"MIIJRAIBADANBgkqhkiG9w0BAQEFAASCCS4wggkqAgEAAoICAQDQmOnboooYGgbU\n"
"rNr+O7xQRrEn/pFdVfWTmW/vCbWWL7BYerxs9Uh7E1PmQpIovdw1DClFx4vMkdvb\n"
"RHzkILY4+mgN05FLdwncxF8X+za4p7nhvJWu2TIinRmkmHRIiXncMU4yqreKnjAX\n"
"9kacWxPMglvnge7CUsywWmaN7qyFT+ywcuN/EGoCiFU7Dzen/HqTgPGeq4gOJ9wl\n"
"ImFuaAiA7696K7UwBI/QEN76QmYOG/iXdZNnp1DDY9h2pA2fmJTmKUzzkk8XXz+Z\n"
"Q4/NHOdzLvl7znRrlI2Y6m4LEr1cCdn7mWNESo5dkif8LVX1j/RDOP6Dtv+oYscG\n"
"TPSSR+Wlcw/0K4tAOILtDs1IVAGhcfZbTXM3EQS66Zx84yrlqkno6JKaGEKvtF9h\n"
"qEYT7lxHP/kIsyxZvXAhJQ8A1ajTDcqetyzphQiaKqeWTEmobibD8JtqshggTVv5\n"
"DtvdU62AfrDfOXub51/+WtdhjCe30aIrLpAaXOTktqYW1tv5Vj986Aj2JPBu7cQZ\n"
"Zxq1KG6KwfeB4EQTxJ5Nt+qJlPC8QPGoep1XejCSgShW6/NjK76C+dXvYFy1Poj+\n"
"4iddW385y1MB+7AwjXEpEQHv5XZ+lkXSk8qtQkgGgQjies6tHKdNv1cfmXMrk0zv\n"
"c+YOQZxCqIUyI0nqyiCA8+2FNYW7PwIDAQABAoICAQCXgxoJsAvB6dWgUFVYaCcl\n"
"39L5i8wmETOom8BTzaeZiNX7zlpigd69lpJQI3ZqJU13Mngf+Qqv8hnRL/PO93uj\n"
"8y31LQDR4YrGUdQIZS2f/iPjtMi8EYJ65cUkap+7uC9NInr8Dkf2ZWPlY7pyAy1k\n"
"VCNRCm1TtDR8u4zV9tBUnHL8ztYzCscVQ9U0ap8wYxDdZsEZUNon/gfG6Sv/t4zF\n"
"qlK42FpooEedB0QOXoAmK2brDDmfBkaBRVqLAinrDDbK3qDIIjNUdJiLSCmBAEeU\n"
"wD/yD0k8gtA+i7iWTmxAF9+/AfC6P7UcffaREpTnIkJ3OUSUgy07L1QEXY0fWx2P\n"
"OFy/ZwUJBvmVCL6dJkDZyBHjDwiu9V09sbdQ9dU+eM8XeaYq1DxWtfuVYnCvId1b\n"
"i6kEZTSAW2IVMazcbZA7GYH+yrYt7Gmhyy/9fR1Kovf6bouJFOhK0oBNNBGf3rZj\n"
"VfZyVJ6U1gGx7DGKGeWHIUswtXEBjpfAZ436k6ruKKyDfneeb82uCf4jp/vFVNN3\n"
"CxiAsCoicULdtKj4U4EmxN9HInGPpLBT32hfHLUnpNzFmoAN6dVRjA++4kzq9Q3Q\n"
"qFgoV7pXP/A2nyZv+QD5GJ218a7B/QThmWsAEEaaNYyNzKmowDckv6cGwTiBv3zD\n"
"7wAQ2n5Vh4bStbiTqRbroQKCAQEA+PRzSPIwlhU0iDhTqTec+RxyYOuQMEizwJHr\n"
"+kgJlvmhUVQ3ALQKzcTRrkz6VAgO/MvoF2gUj6bVLcEo/jqHrc7IC83L4+B7xBFh\n"
"M7dELCvIiETIPivwVSW5vgLY51O2aiJdsZRr7L0jyjQP1uMoc304JegXAC7SxwqH\n"
"+gmsmGMlUfB2I4NYRR12+so7paGqGYgjHaki6e1oNKaWk/8W8FJWh7Vqa9RTEkFD\n"
"oog0JM6yT1ykm2fRdsPaar2lcYbfXAdPuEMpTE+3pQ+au62ZS7vdFGx1FL5ffZyS\n"
"UvmxywJZBvW8Al++PbGuX39AJ948WM/riTt1M2N+AOOsJ32f+QKCAQEA1oAX64id\n"
"eMoXjUjekektTp1hcDRTipF7npjnxI1DUhDJTWgeAUlLzC+RDUpJl64vVF8yEGM2\n"
"N9R1TVQ+B9QglC0OQzpp0h6nCeTcfn12SzzlqsyKzx/07Sucg2VRIdUzpad9gKCR\n"
"Qza5v96rGl0yN7kDrjN9WK511wzLgYdKFkqsvC/bW62HFKkDbfEKqy8qTNy3Haus\n"
"dgfc9uMeqLzuC73bHqVxkRvOdIbRhQw1KGggpnw3Jrs94qydMJu3MYZPfsTbeDvC\n"
"44O83dsrVjOKFXGVTOtZRluHKeeArdtmfUmZaENUXwyaSiGU89Y7AOo+vOFHXMjm\n"
"r/V6fKnVbo/y9wKCAQEAx3NIvWNTK5p3iL7fv81PVIDG3gE7doN4h0og7VYzYKJD\n"
"7J10p3qWwT3y4xrG3vXJ1BwkqEP5XRFC7zI2fl8z/jqRKGvK8pkRbwahgkZMNrsp\n"
"IItChhS7qevcgG9ViRcXKLa5q6CGSpdJiiDlo7o/2S60AiKL8tiQg2hbgiWoAjpE\n"
"Vv44F8GNwWmWvduxp8P6PBRGVegAkbti5fOk5ZLTtNuyeW0NgrALka952UgXxnlW\n"
"f6BwPBUTynukjCm911M/tUIiSzR7bKjdLz9uLvgovXUX7Nnrfx/57u+2hwWGvGb4\n"
"HkxXQOulxVWJpvaS1p4EaP7C7CIXhoEqHNpKPSU3OQKCAQEArJs9JGK13Ro6o42M\n"
"1LtfoxBP9VuWEj6JzJDciDTohGRPqMNsyboyjWeFgL1TxQP8wBcukTNU0M5dalGs\n"
"7N3NLY+oF38s4lGaNwL8T6kkBN1HLw8TcCMWE7fxZWalR+VpfxbtjhEnc3/ZL0W+\n"
"SCPQojh2drqmVjNlThzUsjGs8405vOGB0h8sQPrUcKbz39a/YkSF8hFQYVZogB85\n"
"b61AnSA08E9PuOY4V1qZxUeSiyZnh7ETLE6mOP6QKypS2z5qP+end/QXGr/Kvnh8\n"
"QgyNRD43V0NXfp9uf9DzonOX4J/WG6l6flYE3jxxwVmV92GIBLP/mfFseRG/dAuy\n"
"XRrm9wKCAQAFRj1X8h3ePt7sCUUZXN2XBsEPx7W+hVzl+STu4oDmPMcCL8tL6Ndd\n"
"eUZChT+fZbgSk+rw7OYnNGi5+ES3qRQwXdIJKP8Niu0cHCFPaikWn5rC3Yu8ngsg\n"
"XsrVCNsvfDZkfRtd73s8LFp0+pmTe1AlWVxcDnBZOsoezppDxikHgoRdNbPjGGrO\n"
"T/J8XCPS5aT5TOr1tywKgruqLuZ7v7W6zLDBeImqKGDbH7D5+8vMYUu6d1hoXETp\n"
"DuBmagv/t80FQda1p6b7V0ICvp7GuqGhMjgBFDDszs3cdDZa8sZvheMPOog56EYd\n"
"Rnvuj8XvBcSE6pVTMgkCw06w2fpef7T7\n"
"-----END RSA PRIVATE KEY-----\n"
"-----BEGIN CERTIFICATE-----\n"
"MIIFZTCCA02gAwIBAgIUMAJUww8HOXGFlyZvieX9rzd+1x4wDQYJKoZIhvcNAQEL\n"
"BQAwQjELMAkGA1UEBhMCWFgxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEcMBoGA1UE\n"
"CgwTRGVmYXVsdCBDb21wYW55IEx0ZDAeFw0yMDA4MDQxMDQxMzRaFw0zODA1MjIx\n"
"MDQxMzRaMEIxCzAJBgNVBAYTAlhYMRUwEwYDVQQHDAxEZWZhdWx0IENpdHkxHDAa\n"
"BgNVBAoME0RlZmF1bHQgQ29tcGFueSBMdGQwggIiMA0GCSqGSIb3DQEBAQUAA4IC\n"
"DwAwggIKAoICAQDQmOnboooYGgbUrNr+O7xQRrEn/pFdVfWTmW/vCbWWL7BYerxs\n"
"9Uh7E1PmQpIovdw1DClFx4vMkdvbRHzkILY4+mgN05FLdwncxF8X+za4p7nhvJWu\n"
"2TIinRmkmHRIiXncMU4yqreKnjAX9kacWxPMglvnge7CUsywWmaN7qyFT+ywcuN/\n"
"EGoCiFU7Dzen/HqTgPGeq4gOJ9wlImFuaAiA7696K7UwBI/QEN76QmYOG/iXdZNn\n"
"p1DDY9h2pA2fmJTmKUzzkk8XXz+ZQ4/NHOdzLvl7znRrlI2Y6m4LEr1cCdn7mWNE\n"
"So5dkif8LVX1j/RDOP6Dtv+oYscGTPSSR+Wlcw/0K4tAOILtDs1IVAGhcfZbTXM3\n"
"EQS66Zx84yrlqkno6JKaGEKvtF9hqEYT7lxHP/kIsyxZvXAhJQ8A1ajTDcqetyzp\n"
"hQiaKqeWTEmobibD8JtqshggTVv5DtvdU62AfrDfOXub51/+WtdhjCe30aIrLpAa\n"
"XOTktqYW1tv5Vj986Aj2JPBu7cQZZxq1KG6KwfeB4EQTxJ5Nt+qJlPC8QPGoep1X\n"
"ejCSgShW6/NjK76C+dXvYFy1Poj+4iddW385y1MB+7AwjXEpEQHv5XZ+lkXSk8qt\n"
"QkgGgQjies6tHKdNv1cfmXMrk0zvc+YOQZxCqIUyI0nqyiCA8+2FNYW7PwIDAQAB\n"
"o1MwUTAdBgNVHQ4EFgQUWE9IXPXnQXqYKQYcDSjAxNSwejowHwYDVR0jBBgwFoAU\n"
"WE9IXPXnQXqYKQYcDSjAxNSwejowDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B\n"
"AQsFAAOCAgEAu94JzOvp/NQ+/OPaJw6cilSu5E+S1mcLJiPWmkv41Gwnl86rDfS1\n"
"eVmR58jJhKKypeahNgCMq1dvlIrlIrQEF6hi2JBMjYDPNCWPcWzCqVbOSXfNRKWg\n"
"78nzAuSj0Kp3WEsw95ACmGbJODEW3Ga+AzRIPe4vw35sv06eZsUJJ3QD4mTjOEV9\n"
"UQvVozP5FUCY2VLBjjWT6dDykDiYKTc/xaE2SUgRgykY4nJxihEN6QMLghlEuPyY\n"
"mOKKXXMQDyZalGc9V/VtUY3qNnrbIhcBQeZgKXGRPEqnbTw0H7Q+fSc7xj5bFAmr\n"
"ufjQSWCqqbPNPvgt9NytOUrCzNeKk2x/BUDyI0kHUBj17HtBNo9o4ongcSM2Qs/Z\n"
"kfi/lr/UpqpelIlreC8IJsAY5cgjeChebAwEhf8uGh41grJwmowjVSDqFb0rINTO\n"
"imUEABpFQ/zBGdF1ZG/y07N7mvgEE0UwcH8Si1wSIxWlXw36dED1yoUROKgTXG4k\n"
"ChJmWyPwZoxjBtR86UwIyVgC2Z8pya8h7uvp2wKtlSNUqpXmCvsl+X/zib2YRwI/\n"
"QvxbM4J50AGyIiqXzuULCg2ap9t7Zpc9/+hg0t5BEbym+RbcNLy+lh4ZjrEwH3Xe\n"
"LNIU1lM0Xyg0SY6o1hfH3eiRukedhlametaIGwYG6n5gzYgh7T4W+uI=\n"
"-----END CERTIFICATE-----\n"};

/* These private materials were made with:
 * openssl req -new -x509 -keyout cakey.pem -out cacert.pem -nodes -days 6500 -pkeyopt rsa_keygen_bits:4096
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

SslContext_t::SslContext_t (bool is_server, const std::string &privkeyfile, const std::string &privkey, const std::string &privkeypass, const std::string &certchainfile, const std::string &cert, const std::string &cipherlist, const std::string &ecdh_curve, const std::string &dhparam, int ssl_version) :
	bIsServer (is_server),
	pCtx (NULL),
	PrivateKey (NULL),
	Certificate (NULL)
{
	/* TODO: Also, in this implementation, server-side connections use statically defined X-509 defaults.
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

	int e;
	// As indicated in man(3) ssl_ctx_use_privatekey_file
	// To change a certificate, private key pair the new certificate needs to be set with
	// SSL_use_certificate() or SSL_CTX_use_certificate() before setting the private key with SSL_CTX_use_PrivateKey() or SSL_use_PrivateKey().
	if (certchainfile.length() > 0) {
		e = SSL_CTX_use_certificate_chain_file (pCtx, certchainfile.c_str());
		if (e <= 0) ERR_print_errors_fp(stderr);
		assert (e > 0);
	}
	if (cert.length() > 0) {
		BIO *bio = BIO_new_mem_buf (cert.c_str(), -1);
		assert(bio);
		BIO_set_mem_eof_return(bio, 0);
		X509 * clientCertificate = PEM_read_bio_X509 (bio, NULL, NULL, 0);
		e = SSL_CTX_use_certificate (pCtx, clientCertificate);
		X509_free(clientCertificate);
		BIO_free (bio);
		if (e <= 0) ERR_print_errors_fp(stderr);
		assert (e > 0);
	}
	if (privkeyfile.length() > 0) {
		if (privkeypass.length() > 0) {
			SSL_CTX_set_default_passwd_cb_userdata(pCtx, const_cast<char*>(privkeypass.c_str()));
		}
		e = SSL_CTX_use_PrivateKey_file (pCtx, privkeyfile.c_str(), SSL_FILETYPE_PEM);
		if (e <= 0) ERR_print_errors_fp(stderr);
		assert (e > 0);
	}
	if (privkey.length() > 0) {
		BIO *bio = BIO_new_mem_buf (privkey.c_str(), -1);
		assert(bio);
		BIO_set_mem_eof_return(bio, 0);
		EVP_PKEY * clientPrivateKey = PEM_read_bio_PrivateKey (bio, NULL, NULL, const_cast<char*>(privkeypass.c_str()));
		e = SSL_CTX_use_PrivateKey (pCtx, clientPrivateKey);
		EVP_PKEY_free(clientPrivateKey);
		BIO_free (bio);
		if (e <= 0) {
			BIO *bio_err = BIO_new(BIO_s_mem());
			std::string error_msg;
			if (bio_err != NULL) {
				ERR_print_errors(bio_err);
				char* buf;
				long size = BIO_get_mem_data(bio_err, &buf);
				error_msg.assign(buf,size);
				BIO_free(bio_err);
			}
			throw std::runtime_error (error_msg);
		}
		assert (e > 0);
	}

	if (bIsServer) {
		if (certchainfile.length() == 0 && cert.length() == 0) {
			// ensure default private material is configured for ssl
			e = SSL_CTX_use_certificate (pCtx, DefaultCertificate);
			if (e <= 0) ERR_print_errors_fp(stderr);
			assert (e > 0);
		}
		if (privkeyfile.length() == 0 && privkey.length() == 0) {
			// ensure default private material is configured for ssl
			e = SSL_CTX_use_PrivateKey (pCtx, DefaultPrivateKey);
			if (e <= 0) ERR_print_errors_fp(stderr);
			assert (e > 0);
		}
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

SslBox_t::SslBox_t (bool is_server, const std::string &privkeyfile, const std::string &privkey, const std::string &privkeypass, const std::string &certchainfile, const std::string &cert, bool verify_peer, bool fail_if_no_peer_cert, const std::string &snihostname, const std::string &cipherlist, const std::string &ecdh_curve, const std::string &dhparam, int ssl_version, const uintptr_t binding):
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

	Context = new SslContext_t (bIsServer, privkeyfile, privkey, privkeypass, certchainfile, cert, cipherlist, ecdh_curve, dhparam, ssl_version);
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


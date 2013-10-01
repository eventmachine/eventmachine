package com.rubyeventmachine;

import java.nio.ByteBuffer;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLException;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class SslBox {

	private SSLContext sslContext;
	private SSLEngine sslEngine;

	public SslBox(boolean isServer, KeyStore keyStore, boolean verifyPeer, String host, int port) {
			try {
				sslContext = SSLContext.getInstance("TLS");
				KeyManager[] keyManagers = null;
				TrustManager[] trustManagers = null;

				if (keyStore != null) {
					KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
					kmf.init(keyStore, null);
					keyManagers = kmf.getKeyManagers();
				}

				if (verifyPeer) {
					trustManagers = new TrustManager[] { new CallbackBasedTrustManager() };
				}

				sslContext.init(keyManagers, trustManagers, null);
				sslEngine = sslContext.createSSLEngine(host, port);
				sslEngine.setUseClientMode(!isServer);
			} catch (NoSuchAlgorithmException e) {
				throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
			} catch (UnrecoverableKeyException e) {
				throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
			} catch (KeyStoreException e) {
				throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
			} catch (KeyManagementException e) {
				throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
			}
	}

	private class CallbackBasedTrustManager implements X509TrustManager {
		public void checkClientTrusted(X509Certificate[] chain, String authType)
				throws CertificateException {
		}

		public void checkServerTrusted(X509Certificate[] chain, String authType)
				throws CertificateException {
		}

		public X509Certificate[] getAcceptedIssuers() {
			return null;
		}
	}

	public ByteBuffer encryptOutboundBuffer(ByteBuffer bb) {
		ByteBuffer b = ByteBuffer.allocate(bb.limit());
		try {
			sslEngine.wrap(bb, b);
		} catch (SSLException e) {
			throw new RuntimeException("unable to encrypt outbound data", e);
		}
		b.flip();
		return b;
	};
}
/**
 * $Id$
 * 
 * Author:: Francis Cianfrocca (gmail: blackhedd)
 * Homepage::  http://rubyeventmachine.com
 * Date:: 15 Jul 2007
 * 
 * See EventMachine and EventMachine::Connection for documentation and
 * usage examples.
 * 
 *
 *----------------------------------------------------------------------------
 *
 * Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
 * Gmail: blackhedd
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either: 1) the GNU General Public License
 * as published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version; or 2) Ruby's License.
 * 
 * See the file COPYING for complete licensing information.
 *
 *---------------------------------------------------------------------------
 *
 * 
 */

/**
 * 
 */
package com.rubyeventmachine;

/**
 * @author francis
 *
 */

import java.nio.channels.*;
import java.nio.*;
import java.io.*;
import java.net.Socket;
import java.lang.reflect.Field;
import java.security.*;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.X509TrustManager;

public class EventableSocketChannel extends EventableChannel<ByteBuffer> {
	SelectionKey channelKey;
	SocketChannel channel;

	boolean bCloseScheduled;
	boolean bConnectPending;
	boolean bWatchOnly;
	boolean bAttached;
	boolean bNotifyReadable;
	boolean bNotifyWritable;
	
	SslBox sslBox;
	private KeyStore keyStore;
	private boolean verifyPeer;
	private boolean bIsServer;
	private boolean shouldAcceptSslPeer = false; 	

	public EventableSocketChannel (SocketChannel sc, long _binding, Selector sel, EventCallback callback) {
		super(_binding, sel, callback);
		channel = sc;
		bCloseScheduled = false;
		bConnectPending = false;
		bWatchOnly = false;
		bAttached = false;
		bNotifyReadable = false;
		bNotifyWritable = false;
		bIsServer = false;
	}
	
	public SocketChannel getChannel() {
		return channel;
	}

	public void register() throws ClosedChannelException {
		if (channelKey == null) {
			int events = currentEvents();
			channelKey = channel.register(selector, events, this);
		}
	}

	/**
	 * Terminate with extreme prejudice. Don't assume there will be another pass through
	 * the reactor core.
	 */
	public void close() {
		if (channelKey != null) {
			channelKey.cancel();
			channelKey = null;
		}

		if (bAttached) {
			// attached channels are copies, so reset the file descriptor to prevent java from close()ing it
			Field f;
			FileDescriptor fd;

			try {
				/* do _NOT_ clobber fdVal here, it will break epoll/kqueue on jdk6!
				 * channelKey.cancel() above does not occur until the next call to select
				 * and if fdVal is gone, we will continue to get events for this fd.
				 *
				 * instead, remove fdVal in cleanup(), which is processed via DetachedConnections,
				 * after UnboundConnections but before NewConnections.
				 */

				f = channel.getClass().getDeclaredField("fd");
				f.setAccessible(true);
				fd = (FileDescriptor) f.get(channel);

				f = fd.getClass().getDeclaredField("fd");
				f.setAccessible(true);
				f.set(fd, -1);
			} catch (java.lang.NoSuchFieldException e) {
				e.printStackTrace();
			} catch (java.lang.IllegalAccessException e) {
				e.printStackTrace();
			}

			return;
		}

		try {
			channel.close();
		} catch (IOException e) {
		}
	}

	public void cleanup() {
		if (bAttached) {
			Field f;
			try {
				f = channel.getClass().getDeclaredField("fdVal");
				f.setAccessible(true);
				f.set(channel, -1);
			} catch (java.lang.NoSuchFieldException e) {
				e.printStackTrace();
			} catch (java.lang.IllegalAccessException e) {
				e.printStackTrace();
			}
		}

		channel = null;
	}
	
	public void scheduleOutboundData (ByteBuffer bb) {
		if (!bCloseScheduled && bb.remaining() > 0) {
//			outboundQ.addLast( (sslBox != null) ? sslBox.encryptOutboundBuffer(bb) : bb ); 
			outboundQ.addLast( bb ); 
			updateEvents();
		}
	}
	
	public void scheduleOutboundDatagram (ByteBuffer bb, String recipAddress, int recipPort) {
		throw new RuntimeException ("datagram sends not supported on this channel");
	}
	
	/**
	 * Called by the reactor when we have selected readable.
	 */
	public void readInboundData (ByteBuffer bb) throws IOException {
		if (channel.read(bb) == -1)
			throw new IOException ("eof");
	}

	/**
	 * Called by the reactor when we have selected writable.
	 * Return false to indicate an error that should cause the connection to close.
	 * TODO, VERY IMPORTANT: we're here because we selected writable, but it's always
	 * possible to become unwritable between the poll and when we get here. The way
	 * this code is written, we're depending on a nonblocking write NOT TO CONSUME
	 * the whole outbound buffer in this case, rather than firing an exception.
	 * We should somehow verify that this is indeed Java's defined behavior.
	 * Also TODO, see if we can use gather I/O rather than one write at a time.
	 * Ought to be a big performance enhancer.
	 * @return
	 */
	protected boolean writeOutboundData() throws IOException {
		while (!outboundQ.isEmpty()) {
			ByteBuffer b = outboundQ.getFirst();
			if (b.remaining() > 0)
				channel.write(b);

			// Did we consume the whole outbound buffer? If yes,
			// pop it off and keep looping. If no, the outbound network
			// buffers are full, so break out of here.
			if (b.remaining() == 0)
				outboundQ.removeFirst();
			else
				break;
		}

		if (outboundQ.isEmpty() && !bCloseScheduled) {
			updateEvents();
		}

		// ALWAYS drain the outbound queue before triggering a connection close.
		// If anyone wants to close immediately, they're responsible for clearing
		// the outbound queue.
		return (bCloseScheduled && outboundQ.isEmpty()) ? false : true;
 	}
	
	public void setConnectPending() {
		bConnectPending = true;
		updateEvents();
	}
	
	/**
	 * Called by the reactor when we have selected connectable.
	 * Return false to indicate an error that should cause the connection to close.
	 */
	public boolean finishConnecting() {
		try {
			channel.finishConnect();
			bConnectPending = false;
			updateEvents();
			callback.trigger(binding, EventCode.EM_CONNECTION_COMPLETED, null, 0);
			return true;
		} catch (IOException e) {
			return false;
		}
	}
	
	public boolean scheduleClose (boolean afterWriting) {
		// TODO: What the hell happens here if bConnectPending is set?
		if (!afterWriting)
			outboundQ.clear();

		if (outboundQ.isEmpty())
			return true;
		else {
			updateEvents();
			bCloseScheduled = true;
			return false;
		}
	}

	public void setTlsParms(KeyStore keyStore, boolean verifyPeer) {
		this.keyStore = keyStore;
		this.verifyPeer = verifyPeer;
	}
	
	public void startTls() {
		if (sslBox == null) {
			Object[] peerName = getPeerName();
			int port = (Integer) peerName[0];
			String host = (String) peerName[1];
			X509TrustManager tm = new CallbackBasedTrustManager();
			sslBox = new SslBox(bIsServer, channel, keyStore, tm, verifyPeer, host, port);
			outboundQ.push(SslBox.emptyBuf);
			updateEvents();
		}
	}
	
	public Object[] getPeerName () {
		Socket sock = channel.socket();
		return new Object[]{ sock.getPort(), sock.getInetAddress().getHostAddress() };
	}

	public Object[] getSockName () {
		Socket sock = channel.socket();
		return new Object[]{ sock.getLocalPort(),
							 sock.getLocalAddress().getHostAddress() };
	}

	public void setWatchOnly() {
		bWatchOnly = true;
		updateEvents();
	}
	public boolean isWatchOnly() { return bWatchOnly; }

	public void setAttached() {
		bAttached = true;
	}
	public boolean isAttached() { return bAttached; }

	public void setNotifyReadable (boolean mode) {
		bNotifyReadable = mode;
		updateEvents();
	}
	public boolean isNotifyReadable() { return bNotifyReadable; }

	public void setNotifyWritable (boolean mode) {
		bNotifyWritable = mode;
		updateEvents();
	}
	public boolean isNotifyWritable() { return bNotifyWritable; }

	private void updateEvents() {
		if (channelKey == null)
			return;

		int events = currentEvents();

		if (channelKey.interestOps() != events) {
			channelKey.interestOps(events);
		}
	}

	private int currentEvents() {
		int events = 0;

		if (bWatchOnly)
		{
			if (bNotifyReadable)
				events |= SelectionKey.OP_READ;

			if (bNotifyWritable)
				events |= SelectionKey.OP_WRITE;
		}
		else
		{
			if (bConnectPending)
				events |= SelectionKey.OP_CONNECT;
			else {
				events |= SelectionKey.OP_READ;

				if (!outboundQ.isEmpty())
					events |= SelectionKey.OP_WRITE;
			}
		}

		return events;
	}

	public void setServerMode() {
		bIsServer = true;
	}

	@Override
	protected boolean handshakeNeeded() {
		return sslBox != null && sslBox.handshakeNeeded();
	}

	@Override
	protected boolean performHandshake() {
		if (sslBox == null) return true;
		
		if (sslBox.handshake(channelKey)) {
			if (!sslBox.handshakeNeeded()) {
				callback.trigger(binding, EventCode.EM_SSL_HANDSHAKE_COMPLETED, null, 0);
			}
			return true;
		}
		return false;
	}

	public void acceptSslPeer() {
		this.shouldAcceptSslPeer = true;
	}
	
	public class CallbackBasedTrustManager implements X509TrustManager {
		public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			if (verifyPeer) fireEvent(chain[0]);
		}

		public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			if (verifyPeer) fireEvent(chain[0]);
		}

		public X509Certificate[] getAcceptedIssuers() {
			return new X509Certificate[0];
		}

		private void fireEvent(X509Certificate cert) throws CertificateException {
			
			ByteBuffer data = ByteBuffer.wrap(cert.getEncoded());
			
			callback.trigger(binding, EventCode.EM_SSL_VERIFY, data, 0);
			
			// If we should accept, the trigger will ultimately call our acceptSslPeer method. 
			if (! shouldAcceptSslPeer) {
				throw new CertificateException("JRuby trigger was not fired");
			}
		}
	}

	public byte[] getPeerCert() {
		if (sslBox != null) {
			try {
				javax.security.cert.X509Certificate peerCert = sslBox.getPeerCert();
				return peerCert.getEncoded();
			} catch (Exception e) {
			}
		}
		return null;
	}


}

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
import java.util.*;
import java.io.*;
import java.net.Socket;
import javax.net.ssl.*;
import javax.net.ssl.SSLEngineResult.*;

import java.security.*;

public class EventableSocketChannel implements EventableChannel {
	// TODO, must refactor this to permit channels that aren't sockets.
	SocketChannel channel;
	long binding;
	Selector selector;
	LinkedList<ByteBuffer> outboundQ;
	boolean bCloseScheduled;
	boolean bConnectPending;
	boolean bWatchOnly;
	boolean bNotifyReadable;
	boolean bNotifyWritable;
	
	SSLEngine sslEngine;
	SSLContext sslContext;

	public EventableSocketChannel (SocketChannel sc, long _binding, Selector sel) throws ClosedChannelException {
		channel = sc;
		binding = _binding;
		selector = sel;
		bCloseScheduled = false;
		bConnectPending = false;
		bWatchOnly = false;
		bNotifyReadable = false;
		bNotifyWritable = false;
		outboundQ = new LinkedList<ByteBuffer>();

		updateEvents();
	}
	
	public long getBinding() {
		return binding;
	}

	public SocketChannel getChannel() {
		return channel;
	}
	
	/**
	 * Terminate with extreme prejudice. Don't assume there will be another pass through
	 * the reactor core.
	 */
	public void close() {
		if (bWatchOnly)
			return;

		try {
			channel.close();
		} catch (IOException e) {
		}
	}
	
	public void scheduleOutboundData (ByteBuffer bb) {
		try {
			if ((!bCloseScheduled) && (bb.remaining() > 0)) {
				if (sslEngine != null) {
					ByteBuffer b = ByteBuffer.allocate(32*1024); // TODO, preallocate this buffer.
					sslEngine.wrap(bb, b);
					b.flip();
					outboundQ.addLast(b);
				}
				else {
					outboundQ.addLast(bb);
				}
				channel.register(selector, SelectionKey.OP_WRITE | SelectionKey.OP_READ | (bConnectPending ? SelectionKey.OP_CONNECT : 0), this);
			}
		} catch (ClosedChannelException e) {
			throw new RuntimeException ("no outbound data");			
		} catch (SSLException e) {
			throw new RuntimeException ("no outbound data");
		}
	}
	
	public void scheduleOutboundDatagram (ByteBuffer bb, String recipAddress, int recipPort) {
		throw new RuntimeException ("datagram sends not supported on this channel");
	}
	
	/**
	 * Called by the reactor when we have selected readable.
	 */
	public void readInboundData (ByteBuffer bb) {
		try {
			channel.read(bb);
		} catch (IOException e) {
			throw new RuntimeException ("i/o error");
		}
	}
	/**
	 * Called by the reactor when we have selected writable.
	 * Return false to indicate an error that should cause the connection to close.
	 * We can get here with an empty outbound buffer if bCloseScheduled is true.
	 * TODO, VERY IMPORTANT: we're here because we selected writable, but it's always
	 * possible to become unwritable between the poll and when we get here. The way
	 * this code is written, we're depending on a nonblocking write NOT TO CONSUME
	 * the whole outbound buffer in this case, rather than firing an exception.
	 * We should somehow verify that this is indeed Java's defined behavior.
	 * Also TODO, see if we can use gather I/O rather than one write at a time.
	 * Ought to be a big performance enhancer.
	 * @return
	 */
	public boolean writeOutboundData(){
		while (!outboundQ.isEmpty()) {
			ByteBuffer b = outboundQ.getFirst();
			try {
				if (b.remaining() > 0)
					channel.write(b);
			}
			catch (IOException e) {
				return false;
			}

			// Did we consume the whole outbound buffer? If yes,
			// pop it off and keep looping. If no, the outbound network
			// buffers are full, so break out of here.
			if (b.remaining() == 0)
				outboundQ.removeFirst();
			else
				break;
		}

		if (outboundQ.isEmpty()) {
			try {
				channel.register(selector, SelectionKey.OP_READ, this);
			} catch (ClosedChannelException e) {
			}
		}
		
		// ALWAYS drain the outbound queue before triggering a connection close.
		// If anyone wants to close immediately, they're responsible for clearing
		// the outbound queue.
		return (bCloseScheduled && outboundQ.isEmpty()) ? false : true;
 	}
	
	public void setConnectPending() throws ClosedChannelException {
		channel.register(selector, SelectionKey.OP_CONNECT, this);
		bConnectPending = true;
	}
	
	/**
	 * Called by the reactor when we have selected connectable.
	 * Return false to indicate an error that should cause the connection to close.
	 * @throws ClosedChannelException
	 */
	public boolean finishConnecting() throws ClosedChannelException {
		try {
			channel.finishConnect();
		}
		catch (IOException e) {
			return false;
		}
		bConnectPending = false;
		channel.register(selector, SelectionKey.OP_READ | (outboundQ.isEmpty() ? 0 : SelectionKey.OP_WRITE), this);
		return true;
	}
	
	public void scheduleClose (boolean afterWriting) {
		// TODO: What the hell happens here if bConnectPending is set?
		if (!afterWriting)
			outboundQ.clear();
		try {
			channel.register(selector, SelectionKey.OP_READ|SelectionKey.OP_WRITE, this);
		} catch (ClosedChannelException e) {
			throw new RuntimeException ("unable to schedule close"); // TODO, get rid of this.
		}
		bCloseScheduled = true;
	}
	public void startTls() {
		if (sslEngine == null) {
			try {
				sslContext = SSLContext.getInstance("TLS");
				sslContext.init(null, null, null); // TODO, fill in the parameters.
				sslEngine = sslContext.createSSLEngine(); // TODO, should use the parameterized version, to get Kerb stuff and session re-use.
				sslEngine.setUseClientMode(false);
			} catch (NoSuchAlgorithmException e) {
				throw new RuntimeException ("unable to start TLS"); // TODO, get rid of this.				
			} catch (KeyManagementException e) {
				throw new RuntimeException ("unable to start TLS"); // TODO, get rid of this.				
			}
		}
		System.out.println ("Starting TLS");
	}
	
	public ByteBuffer dispatchInboundData (ByteBuffer bb) throws SSLException {
		if (sslEngine != null) {
			if (true) throw new RuntimeException ("TLS currently unimplemented");
			System.setProperty("javax.net.debug", "all");
			ByteBuffer w = ByteBuffer.allocate(32*1024); // TODO, WRONG, preallocate this buffer.
			SSLEngineResult res = sslEngine.unwrap(bb, w);
			if (res.getHandshakeStatus() == HandshakeStatus.NEED_TASK) {
				Runnable r;
				while ((r = sslEngine.getDelegatedTask()) != null) {
					r.run();
				}
			}
			System.out.println (bb);
			w.flip();
			return w;
		}
		else
			return bb;
	}

	public void setCommInactivityTimeout (long seconds) {
		// TODO
		System.out.println ("SOCKET: SET COMM INACTIVITY UNIMPLEMENTED " + seconds);
	}

	public Object[] getPeerName () {
		Socket sock = channel.socket();
		return new Object[]{ sock.getPort(), sock.getInetAddress().getHostAddress() };
	}

	public void setWatchOnly() {
		bWatchOnly = true;
		updateEvents();
	}
	public boolean isWatchOnly() { return bWatchOnly; }

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
		int events = 0;

		if (bWatchOnly) {
			if (bNotifyReadable)
				events |= SelectionKey.OP_READ;

			if (bNotifyWritable)
				events |= SelectionKey.OP_WRITE;
		} else {
			events |= SelectionKey.OP_READ;

			if (bConnectPending)
				events |= SelectionKey.OP_CONNECT;

			if (!outboundQ.isEmpty())
				events |= SelectionKey.OP_WRITE;
		}

		try {
			channel.register(selector, events, this);
		} catch (ClosedChannelException e) {
			// what should this do? scheduleClose/detach?
			System.err.println("ERROR: ClosedChannelException");
		}
	}
}

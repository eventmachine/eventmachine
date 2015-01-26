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


package com.rubyeventmachine;

import java.nio.ByteBuffer;
import java.nio.channels.ClosedChannelException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.DatagramChannel;
import java.io.*;
import java.net.*;

public class EventableDatagramChannel extends EventableChannel<DatagramPacket> {
	
	DatagramChannel channel;
	boolean bCloseScheduled;
	SocketAddress returnAddress;

	public EventableDatagramChannel (DatagramChannel dc, long _binding, Selector sel, EventCallback callback) throws ClosedChannelException {
		super(_binding, sel, callback);
		channel = dc;
		bCloseScheduled = false;
		
		dc.register(selector, SelectionKey.OP_READ, this);
	}

	public void scheduleOutboundData (ByteBuffer bb) {
 		try {
			if ((!bCloseScheduled) && (bb.remaining() > 0)) {
				outboundQ.addLast(new DatagramPacket(bb, returnAddress));
 				channel.register(selector, SelectionKey.OP_WRITE | SelectionKey.OP_READ, this);
			}
		} catch (ClosedChannelException e) {
			throw new RuntimeException ("no outbound data");			
		}
	}
	
	public void scheduleOutboundDatagram (ByteBuffer bb, String recipAddress, int recipPort) {
 		try {
			if ((!bCloseScheduled) && (bb.remaining() > 0)) {
				outboundQ.addLast(new DatagramPacket (bb, new InetSocketAddress (recipAddress, recipPort)));
 				channel.register(selector, SelectionKey.OP_WRITE | SelectionKey.OP_READ, this);
			}
		} catch (ClosedChannelException e) {
			throw new RuntimeException ("no outbound data");			
		}
	}
	
	public boolean scheduleClose (boolean afterWriting) {
		System.out.println ("NOT SCHEDULING CLOSE ON DATAGRAM");
		return false;
	}
	
	public void startTls() {
		throw new RuntimeException ("TLS is unimplemented on this Channel");
	}

	public void register() throws ClosedChannelException {
		// TODO
	}

	/**
	 * Terminate with extreme prejudice. Don't assume there will be another pass through
	 * the reactor core.
	 */
	public void close() {
		try {
			channel.close();
		} catch (IOException e) {
		}
	}
	
	public void readInboundData (ByteBuffer dst) {
		returnAddress = null;
		try {
			// If there is no datagram available (we're nonblocking after all),
			// then channel.receive returns null.
			returnAddress = channel.receive(dst);
		} catch (IOException e) {
			// probably a no-op. The caller will see the empty (or even partial) buffer
			// and presumably do the right thing.
		}
	}
	
	protected boolean writeOutboundData() {
		while (!outboundQ.isEmpty()) {
			DatagramPacket p = outboundQ.getFirst();
			int written = 0;
			try {
				// With a datagram socket, it's ok to send an empty buffer.
				written = channel.send(p.bb, p.recipient);
			}
			catch (IOException e) {
				return false;
			}

			/* Did we consume the whole outbound buffer? If yes, pop it off and
			 * keep looping. If no, the outbound network buffers are full, so break
			 * out of here. There's a flaw that affects outbound buffers that are intentionally
			 * empty. We can tell whether they got sent or not. So we assume they were.
			 * TODO: As implemented, this ALWAYS discards packets if they were at least
			 * partially written. This matches the behavior of the C++ EM. My judgment
			 * is that this is less surprising than fragmenting the data and sending multiple
			 * packets would be. I could be wrong, so this is subject to change.
			 */

			if ((written > 0) || (p.bb.remaining() == 0))
				outboundQ.removeFirst();
			else
				break;
		}

		if (outboundQ.isEmpty()) {
			try {
				channel.register(selector, SelectionKey.OP_READ, this);
			} catch (ClosedChannelException e) {}
		}
		
		// ALWAYS drain the outbound queue before triggering a connection close.
		// If anyone wants to close immediately, they're responsible for clearing
		// the outbound queue.
		return (bCloseScheduled && outboundQ.isEmpty()) ? false : true;
	}

	public Object[] getPeerName () {
		if (returnAddress != null) {
			InetSocketAddress inetAddr = (InetSocketAddress) returnAddress;
			return new Object[]{ inetAddr.getPort(), inetAddr.getHostName() };
		} else {
			return null;
		}
	}

	public Object[] getSockName () {
		DatagramSocket socket = channel.socket();
		return new Object[]{ socket.getLocalPort(),
							 socket.getLocalAddress().getHostAddress() };
	}

	public boolean isWatchOnly() { return false; }
	public boolean isNotifyReadable() { return false; }
	public boolean isNotifyWritable() { return false; }

	@Override
	protected boolean handshakeNeeded() {
		return false;
	}

	@Override
	protected boolean performHandshake() {
		return true;
	}
}

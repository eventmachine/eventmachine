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
import java.io.IOException;
import java.nio.channels.ClosedChannelException;
import java.nio.channels.Selector;
import java.util.LinkedList;

public abstract class EventableChannel<OutboundPacketType> {
	protected final long binding;
	protected final Selector selector;
	protected final LinkedList<OutboundPacketType> outboundQ;
	protected final EventCallback callback;
	private final ByteBuffer readBuffer;

	public EventableChannel(long binding, Selector selector,
			EventCallback callback) {
		this.binding = binding;
		this.selector = selector;
		this.callback = callback;
		this.outboundQ = new LinkedList<OutboundPacketType>();
		this.readBuffer = ByteBuffer.allocate(32*1024); // don't use a direct buffer. Ruby doesn't seem to like them.
	}

	public abstract void scheduleOutboundData(ByteBuffer bb);

	public abstract void scheduleOutboundDatagram(ByteBuffer bb,
			String recipAddress, int recipPort);

	public abstract boolean scheduleClose(boolean afterWriting);

	public abstract void startTls();

	public long getBinding() {
		return binding;
	}

	public abstract void register() throws ClosedChannelException;

	/**
	 * This is called by the reactor after it finishes running. The idea is to
	 * free network resources.
	 */
	public abstract void close();

	public void setCommInactivityTimeout (long seconds) {
		// TODO
		System.out.println ("SET COMM INACTIVITY UNIMPLEMENTED IN JRUBY" + seconds);
	}

	public abstract Object[] getPeerName();

	public abstract Object[] getSockName();

	public abstract boolean isWatchOnly();

	public abstract boolean isNotifyReadable();

	public abstract boolean isNotifyWritable();
	
	protected abstract boolean handshakeNeeded();
	protected abstract boolean performHandshake();
	
	protected abstract void readInboundData(ByteBuffer dst) throws IOException;

	public boolean read() {
		if (handshakeNeeded()) {
			return performHandshake();
		} else if (isWatchOnly() && isNotifyReadable()) {
			callback.trigger(binding, EventCode.EM_CONNECTION_NOTIFY_READABLE, null, 0);
		} else {
			readBuffer.clear();

			try {
				readInboundData(readBuffer);
				readBuffer.flip();
				if (readBuffer.limit() > 0)
					callback.trigger(binding, EventCode.EM_CONNECTION_READ,	readBuffer, 0);
			} catch (IOException e) {
				return false;
			}
		}
		return true;
	}

	protected abstract boolean writeOutboundData() throws IOException;

	public boolean write() {
		if (handshakeNeeded()) {
			return performHandshake();
		} else if (isWatchOnly() || isNotifyWritable()) {
			callback.trigger(binding, EventCode.EM_CONNECTION_NOTIFY_WRITABLE, null, 0);
		} else {
			try {
				return writeOutboundData();
			} catch (IOException e) {
				return false;
			}
		}
		return true;
	}
}

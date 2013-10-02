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
	
	public EventableChannel(long binding, Selector selector) {
		this.binding = binding;
		this.selector = selector;
		this.outboundQ = new LinkedList<OutboundPacketType>();
	}

	public abstract void scheduleOutboundData (ByteBuffer bb);
	
	public abstract void scheduleOutboundDatagram (ByteBuffer bb, String recipAddress, int recipPort);
	
	public abstract boolean scheduleClose (boolean afterWriting);
	
	public abstract void startTls();
	
	public long getBinding() {
		return binding;
	}
	
	public abstract void readInboundData (ByteBuffer dst) throws IOException;
	
	public abstract void register() throws ClosedChannelException;

	/**
	 * This is called by the reactor after it finishes running.
	 * The idea is to free network resources.
	 */
	public abstract void close();
	
	public abstract boolean writeOutboundData() throws IOException;

	public abstract void setCommInactivityTimeout (long seconds);

	public abstract Object[] getPeerName();
	public abstract Object[] getSockName();

	public abstract boolean isWatchOnly();

	public abstract boolean isNotifyReadable();
	public abstract boolean isNotifyWritable();

}

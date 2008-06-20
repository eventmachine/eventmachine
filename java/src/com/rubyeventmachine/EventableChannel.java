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

public interface EventableChannel {
	
	public void scheduleOutboundData (ByteBuffer bb);
	
	public void scheduleOutboundDatagram (ByteBuffer bb, String recipAddress, int recipPort);
	
	public void scheduleClose (boolean afterWriting);
	
	public void startTls();
	
	public String getBinding();
	
	public void readInboundData (ByteBuffer dst);
	
	/**
	 * This is called by the reactor after it finishes running.
	 * The idea is to free network resources.
	 */
	public void close();
	
	public boolean writeOutboundData();

	public void setCommInactivityTimeout (long seconds);
}

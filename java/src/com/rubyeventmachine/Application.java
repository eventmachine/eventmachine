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

import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.*;
import java.io.*;
import java.net.*;
import java.net.SocketAddress;

/**
 * @author francis
 *
 */
public class Application {
	
	
	public class Reactor extends EmReactor {

		private Application application;
		private TreeMap<String, Timer> timers;
		private TreeMap<String, Connection> connections;
		private TreeMap<String, ConnectionFactory> acceptors;
		/**
		 * 
		 */
		public Reactor (Application app) {
			application = app;
			timers = new TreeMap<String, Timer>();
			connections = new TreeMap<String, Connection>();
			acceptors = new TreeMap<String, ConnectionFactory>();
		}


		public void eventCallback (String sig, int eventType, ByteBuffer data) {
			if (eventType == EM_TIMER_FIRED) {
				String timersig = new String (data.array());
				//System.out.println ("EVSIG "+sig + "..."+new String(data.array()));
				Timer r = timers.remove(timersig);
				if (r != null)
					r._fire();
				else
					throw new RuntimeException ("unable to run unknown timer");
			}
			else if (eventType == EM_CONNECTION_COMPLETED) {
				Connection c = connections.get(sig);
				if (c != null) {
					c.connectionCompleted();
				}
				else
					throw new RuntimeException ("connection completed to unknown object");

			}
			else if (eventType == EM_CONNECTION_UNBOUND) {
				Connection c = connections.get(sig);
				if (c != null) {
					c.unbind();
				}
				else
					throw new RuntimeException ("unbind received on unknown object");
			}
			else if (eventType == EM_CONNECTION_ACCEPTED) {
				ConnectionFactory f = acceptors.get(sig);
				if (f != null) {
					Connection c = f.connection();
					c.signature = new String (data.array());
					c.application = application;
					connections.put(c.signature, c);
					c.postInit();
					//System.out.println (sig+"..."+new String(data.array()));
				}
				else
					throw new RuntimeException ("received connection on unknown acceptor");
			}
			else if (eventType == EM_CONNECTION_READ) {
				Connection c = connections.get(sig);
				if (c != null) {
					c.receiveData(data);
				}
				else throw new RuntimeException ("received data on unknown object");
			}
			else {
				System.out.println ("unknown event type: " + eventType);
			}
		}
	}


	Reactor reactor;
	
	public Application() {
		reactor = new Reactor (this);
	}
	public void addTimer (double seconds, Timer t) {
		t.application = this;
		t.interval = seconds;
		String s = reactor.installOneshotTimer ((int)(seconds * 1000));
		reactor.timers.put(s, t);
		
	}

	public void bindConnect (String bindAddr, int bindPort, String host, int port, Connection c) {
		try {
			String s = reactor.connectTcpServer(bindAddr, bindPort, host, port);
			c.application = this;
			c.signature = s;
			reactor.connections.put(s, c);
			c.postInit();
		} catch (ClosedChannelException e) {}
	}

	public void connect (String host, int port, Connection c) {
		bindConnect(null, 0, host, port, c);
	}
	
	public void startServer (SocketAddress sa, ConnectionFactory f) throws EmReactorException {
		String s = reactor.startTcpServer(sa);
		reactor.acceptors.put(s, f);
	}
	
	public void stop() {
		reactor.stop();
	}
	public void run() {
		try {
			reactor.run();
		} catch (IOException e) {}
	}
	public void run (final Runnable r) {
		addTimer(0, new Timer() {
			public void fire() {
				r.run();
			}
		});
		run();
	}
	
	public void sendData (String sig, ByteBuffer bb) {
		try {
			reactor.sendData(sig, bb);
		} catch (IOException e) {}
	}
	
	public void sendDatagram (String sig, ByteBuffer bb, InetSocketAddress target) {
		reactor.sendDatagram(sig, bb, target.getHostName(), target.getPort());
	}
	
	public void closeConnection (String sig, boolean afterWriting) {
		try {
			reactor.closeConnection(sig, afterWriting);
		} catch (ClosedChannelException e) {}
	}
	
	public void openDatagramSocket (Connection c) {
		openDatagramSocket (new InetSocketAddress ("0.0.0.0", 0), c);
	}
	public void openDatagramSocket (InetSocketAddress addr, Connection c) {
		try {
			String s = reactor.openUdpSocket(addr);
			c.application = this;
			c.signature = s;
			reactor.connections.put(s, c);
			c.postInit();
		} catch (ClosedChannelException e) {
		} catch (IOException e) {
			System.out.println ("Bad Datagram socket "+e+" "+addr);
			/* TODO, can't catch this here, because it can happen on a bad address */
		}
	}
}

package com.rubyeventmachine;

import java.net.SocketAddress;
import java.nio.ByteBuffer;

class DatagramPacket {
	public ByteBuffer bb;
	public SocketAddress recipient;
	public DatagramPacket (ByteBuffer _bb, SocketAddress _recipient) {
		bb = _bb;
		recipient = _recipient;
	}
}
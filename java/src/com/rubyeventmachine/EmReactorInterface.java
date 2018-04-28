package com.rubyeventmachine;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

public interface EmReactorInterface
{
	void eventCallback (long sig, int eventType, ByteBuffer data, long data2);

	void eventCallback (long sig, int eventType, ByteBuffer data);

	void run();

	void stop();

	long installOneshotTimer (long milliseconds);

	long startTcpServer (SocketAddress sa) throws EmReactorException;

	long startTcpServer (String address, int port) throws EmReactorException;

	void stopTcpServer (long signature) throws IOException;

	long openUdpSocket (InetSocketAddress address) throws IOException;

	long openUdpSocket (String address, int port) throws IOException;

	void sendData (long sig, ByteBuffer bb) throws IOException;

	void sendData (long sig, byte[] data) throws IOException;

	void setCommInactivityTimeout (long sig, long mills);

	void sendDatagram (long sig, byte[] data, int length, String recipAddress, int recipPort);

	void sendDatagram (long sig, ByteBuffer bb, String recipAddress, int recipPort);

	long connectTcpServer (String address, int port);

	long connectTcpServer (String bindAddr, int bindPort, String address, int port);

	void closeConnection (long sig, boolean afterWriting);

	void signalLoopbreak();

	void startTls (long sig) throws NoSuchAlgorithmException, KeyManagementException;

	void setTimerQuantum (int mills);

	Object[] getPeerName (long sig);

	long attachChannel (SocketChannel sc, boolean watch_mode);

	SocketChannel detachChannel (long sig);

	void setNotifyReadable (long sig, boolean mode);

	void setNotifyWritable (long sig, boolean mode);

	boolean isNotifyReadable (long sig);

	boolean isNotifyWritable (long sig);

	int getConnectionCount();
}

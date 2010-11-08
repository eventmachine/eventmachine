package com.rubyeventmachine;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

public class NullEmReactor implements EmReactorInterface
{
	public void eventCallback(long sig, int eventType, ByteBuffer data, long data2)
	{

	}

	public void eventCallback(long sig, int eventType, ByteBuffer data)
	{

	}

	public void run()
	{

	}

	public void stop()
	{

	}

	public long installOneshotTimer(long milliseconds)
	{
		return 0;
	}

	public long startTcpServer(SocketAddress sa) throws EmReactorException
	{
		return 0;
	}

	public long startTcpServer(String address, int port) throws EmReactorException
	{
		return 0;
	}

	public void stopTcpServer(long signature) throws IOException
	{

	}

	public long openUdpSocket(InetSocketAddress address) throws IOException
	{
		return 0;
	}

	public long openUdpSocket(String address, int port) throws IOException
	{
		return 0;
	}

	public void sendData(long sig, ByteBuffer bb) throws IOException
	{

	}

	public void sendData(long sig, byte[] data) throws IOException
	{

	}

	public void setCommInactivityTimeout(long sig, long mills)
	{

	}

	public void sendDatagram(long sig, byte[] data, int length, String recipAddress, int recipPort)
	{

	}

	public void sendDatagram(long sig, ByteBuffer bb, String recipAddress, int recipPort)
	{

	}

	public long connectTcpServer(String address, int port)
	{
		return 0;
	}

	public long connectTcpServer(String bindAddr, int bindPort, String address, int port)
	{
		return 0;
	}

	public void closeConnection(long sig, boolean afterWriting)
	{

	}

	public void signalLoopbreak()
	{

	}

	public void startTls(long sig) throws NoSuchAlgorithmException, KeyManagementException
	{

	}

	public void setTimerQuantum(int mills)
	{

	}

	public Object[] getPeerName(long sig)
	{
		return new Object[0];
	}

	public long attachChannel(SocketChannel sc, boolean watch_mode)
	{
		return 0;
	}

	public SocketChannel detachChannel(long sig)
	{
		return null;
	}

	public void setNotifyReadable(long sig, boolean mode)
	{

	}

	public void setNotifyWritable(long sig, boolean mode)
	{

	}

	public boolean isNotifyReadable(long sig)
	{
		return false;
	}

	public boolean isNotifyWritable(long sig)
	{
		return false;
	}

	public int getConnectionCount()
	{
		return 0;
	}
}

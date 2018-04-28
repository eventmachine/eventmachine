package com.rubyeventmachine;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ClosedChannelException;

public class NullEventableChannel implements EventableChannel
{
	public void scheduleOutboundData(ByteBuffer bb)
	{
	}

	public void scheduleOutboundDatagram(ByteBuffer bb, String recipAddress, int recipPort)
	{
	}

	public boolean scheduleClose(boolean afterWriting)
	{
		return false;
	}

	public void startTls()
	{
	}

	public long getBinding()
	{
		return 0;
	}

	public void readInboundData(ByteBuffer dst) throws IOException
	{
	}

	public void register() throws ClosedChannelException
	{
	}

	public void close()
	{
	}

	public boolean writeOutboundData() throws IOException
	{
		return false;
	}

	public void setCommInactivityTimeout(long seconds)
	{
	}

	public Object[] getPeerName()
	{
		return new Object[0];
	}

	public Object[] getSockName()
	{
		return new Object[0];
	}

	public boolean isWatchOnly()
	{
		return false;
	}

	public boolean isNotifyReadable()
	{
		return false;
	}

	public boolean isNotifyWritable()
	{
		return false;
	}

	public long getOutboundDataSize ()
	{
		return 0;
	}
}

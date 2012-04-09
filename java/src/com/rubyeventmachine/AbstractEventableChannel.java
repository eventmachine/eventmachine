package com.rubyeventmachine;

public abstract class AbstractEventableChannel implements EventableChannel {
	protected long inactivityTimeout = 0;
	protected long lastActivityTime = System.currentTimeMillis();

	public void setCommInactivityTimeout (double seconds) {
		inactivityTimeout = (long) (seconds * 1000);
	}
	
	public long getCommInactivityTimeout() {
		return inactivityTimeout;
	}

	public void setLastCommActivityTime(long time) {
		lastActivityTime = time;
	}

	public long getLastCommActivityTime() {
		return lastActivityTime;
	}
}

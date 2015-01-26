package com.rubyeventmachine;

import java.nio.ByteBuffer;

public interface EventCallback {
	void trigger(long sig, EventCode eventType, ByteBuffer data, long data2);
}
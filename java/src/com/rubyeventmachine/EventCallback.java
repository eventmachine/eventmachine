package com.rubyeventmachine;

import java.nio.ByteBuffer;

public interface EventCallback {
	void trigger(long sig, int eventType, ByteBuffer data, long data2);
}
/*****************************************************************************

$Id$

File:     eventmachine.h
Date:     15Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/

#ifndef __EVMA_EventMachine__H_
#define __EVMA_EventMachine__H_

#if __cplusplus
extern "C" {
#endif

	enum { // Event names
		EM_TIMER_FIRED = 100,
		EM_CONNECTION_READ = 101,
		EM_CONNECTION_UNBOUND = 102,
		EM_CONNECTION_ACCEPTED = 103,
		EM_CONNECTION_COMPLETED = 104,
		EM_LOOPBREAK_SIGNAL = 105,
		EM_CONNECTION_NOTIFY_READABLE = 106,
		EM_CONNECTION_NOTIFY_WRITABLE = 107,
		EM_SSL_HANDSHAKE_COMPLETED = 108,
		EM_SSL_VERIFY = 109,
		EM_PROXY_TARGET_UNBOUND = 110

	};

#if __cplusplus
}
#endif


#endif // __EventMachine__H_


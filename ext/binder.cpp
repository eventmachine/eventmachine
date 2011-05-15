/*****************************************************************************

$Id$

File:     binder.cpp
Date:     07Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/

#include "project.h"

#define DEV_URANDOM "/dev/urandom"


map<unsigned long, Bindable_t*> Bindable_t::BindingBag;


/********************************
STATIC Bindable_t::CreateBinding
********************************/

unsigned long Bindable_t::CreateBinding()
{
	static unsigned long num = 0;
	while(BindingBag[++num]);
	return num;
}

/*****************************
STATIC: Bindable_t::GetObject
*****************************/

Bindable_t *Bindable_t::GetObject (const unsigned long binding)
{
  map<unsigned long, Bindable_t*>::const_iterator i = BindingBag.find (binding);
  if (i != BindingBag.end())
    return i->second;
  else
    return NULL;
}


/**********************
Bindable_t::Bindable_t
**********************/

Bindable_t::Bindable_t()
{
	Binding = Bindable_t::CreateBinding();
	BindingBag [Binding] = this;
}


/***********************
Bindable_t::~Bindable_t
***********************/

Bindable_t::~Bindable_t()
{
	BindingBag.erase (Binding);
}



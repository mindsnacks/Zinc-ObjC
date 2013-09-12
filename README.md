# Zinc-ObjC

[![Build Status](https://travis-ci.org/mindsnacks/Zinc-ObjC.png?branch=master)](https://travis-ci.org/mindsnacks/Zinc-ObjC)

Objective-C client for Zinc asset distribution system. Common use cases for
Zinc are for downloading content purchased through an in-app-purchase
mechanism, or to avoid packaging large files inside your app package if they
may not be needed.

## Feature Highlights

 - Zinc bundles are presented as familiar NSBundles
 - Zinc bundles can be updated manually or automatically
 - A Zinc bundle will never be updated while it's in use.
 - Multiple remote catalogs can be tracked.
 - The Zinc client knows about which files have changed, and only downloads the
   necessary files.
 - Bundles can be filtered into "flavors" (to support 1x, 2x images, etc)

## Status:

Zinc-ObjC is under *active* development 'beta' quality.

## About Zinc

More about the Zinc system can be found at the main [Zinc repo](http://github.com/mindsnacks/Zinc).

Here's an except from the main Zinc documentation:

The central concept in Zinc is a "bundle", which is just a group of assets. For
example, a bundle could be a level for a game, which includes spritesheets,
background music, and metadata.

Zinc bundles are also versioned, which means they can be updated. For example,
if you wanted to change the background music in a game, you can do that by
pushing a new version of that bundle.

Finally, Zinc also has a notion of "distributions" for a bundles, which are
basically just tags. This allows clients to track a tag such as `master`
instead of the version directly. Then whenever the `master` distribution is
updated, clients will automatically download the changes.

## Acknowledgements

Zinc-ObjC incorporates code from the following:

 - [AFNetworking](https://github.com/AFNetworking/AFNetworking)
 - [KSJSON](https://github.com/kstenerud/KSJSON)
 - [AMFoundation](https://github.com/amrox/AMFoundation)
 - [Light-Untar-for-iOS](https://github.com/mhausherr/Light-Untar-for-iOS)

## License

Zinc-ObjC is distributed under a BSD-style license.

	Copyright (c) 2011-2012 MindSnacks (http://mindsnacks.com/)
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.


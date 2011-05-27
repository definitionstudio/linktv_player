Link TV Player
==============

The Link TV Player is a standalone Flash® video player, written in ActionScript 3.


Features
--------
* Streaming (RTMP) or progressive (HTTP) video sources
* MP4 (H.264) and FLV/F4V video support
* YouTube video support
* "High quality" video option
* Segment/chapter support
* Embedded display mode


Dependencies
------------
* [Flash Player](http://www.adobe.com/go/getflash/) version 9.0.115 or higher
* [JSON-js](https://github.com/douglascrockford/JSON-js) or equivalent JSON serializer


Configuration
-------------

### Flashvars:

* config (string): JSON-encoded config object (see below)
* configUrl (string): URL of JSON config data (valid only if _config_ not provided)

### Config object:

* startTime (integer): Video start time (default: 0)
* playerId (string): Player DOM ID (required when passing eventHandler)
* eventHandler (string): JavaScript callback for handling player events
* embedded (boolean): true for embedded display mode (iframe)
* permalinkId (string): Video GUID
* permalinkUrl (string): Video URL
* streamHost (string): RTMP host, with prefix
* mediaType (string): "internal" or "youtube"
* mediaStatus (object)
	* available (boolean)
	* message (string)
* media (array)
	* (object):
		* url (string): Internal or YouTube URL
		* size (integer): File size, in bytes
* duration (integer): Video duration, in seconds
* title (string): Video title
* description (string): Video description text
* posterImage (string): Image URL
* posterAttribution (string): Image attribution text
* segments (array):
	* (object):
		* id (integer): Numeric ID
		* startTime (integer): Start time, in seconds
		* title (string): Segment title
		* thumbnail (string): Image URL
* trackPlayUrl (string): URL for tracking play event (POST)
* userId (string): Optional user ID for play event tracking
* googleAnalyticsId (string): Google Analytics ID for GA event tracking
* player (object): Player UI customizations
	* controlsBgColor (string): Hex color
	* controlsBgOpacity (float): Decimal, 0.0 – 1.0
	* controlsTextColor (string): Hex color
	* progressBarTrackColor (string): Hex color
	* progressBarTrackOpacity (float): Decimal, 0.0 – 1.0
	* progressBarLoadColor (string): Hex color
	* progressBarColor (string): Hex color
	* segmentNavColor (string): Hex color
	* segmentNavOpacity (float): Decimal, 0.0 – 1.0
	* segmentNavActiveColor (string): Hex color
	* segmentNavActiveOpacity (float): Decimal, 0.0 – 1.0
	* segmentInfoBgColor (string): Hex color
	* segmentInfoBgOpacity (float): Decimal, 0.0 – 1.0
	* segmentInfoTextColor (string): Hex color
	* headerBgColor (string): Hex color
	* headerBgOpacity (float): Decimal, 0.0 – 1.0
	* headerTextColor (string): Hex color
	* linkTextColor (string): Hex color
	* tooltipBgColor (string): Hex color
	* tooltipBgOpacity (float): Decimal, 0.0 – 1.0
	* tooltipTextColor (string): Hex color


External Methods
----------------
* getCurrentTime(): Returns playhead time, in seconds
* seekToSegment(segmentId): Seek to beginning of segment


Acknowledgements
----------------
* Developed by [Rob DiCiuccio](https://github.com/robdiciuccio) for [Definition LLC](http://www.definitionstudio.com)
* Produced by [Link Media, Inc.](http://www.linktv.org)

Google Analytics Tracking For Adobe Flash, an Apache 2.0-licensed project, is bundled with this distribution.
More information available at <http://code.google.com/p/gaforflash/>


License
-------
Distributed under the MIT License, copyright (c) 2011 Definition LLC.
A project of Link Media, Inc.
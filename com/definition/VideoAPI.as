package com.definition
{

    import flash.events.*;
	
	import com.definition.Player;
			
	public interface VideoAPI {
		
		// init: call after event listeners are assigned
		
		function init():void;
		
		// getter methods
		
		function isReady():Boolean;		// API is ready for calls
		
		function isLoaded():Boolean;	// video is loaded
		
		function isPlaying():Boolean;
		
		function isComplete():Boolean;
		
		function hasBusyIndicator():Boolean;	// don't show loader symbol if true
		
		function hasPosterImage():Boolean;		// don't display poster img if player has its own
		
		function hasControls():Boolean;			// don't draw controls if player has its own
		
		function getCurrentTime():Number;
		
		function getDuration():Number;
		
		function getVolume():Number;
		
		function getBytesLoaded():Number;
		
		function getBytesTotal():Number;
		
		function getQualityLevels():Array;
				
		// playback controls
		
		function play():void;
		
		function pause():void;
		
		function mute():void;
		
		function unMute():void;
		
		function seekTo(seconds:int, autoPlay:Boolean=false):void;
		
		// resize & quality
		
		function setSize(width:Number, height:Number):void;
		
		function setQualityLevel(qualityLevel:*):void;	// accept string or integer
		
		// events (dispatched)
		
		// NOTE: AS3 does not support event dispatch definitions in interfaces. This must be done manually.
		
		// EVENT: ready
		// EVENT: error
		// EVENT: stateChange
		//		STATES:
		//			-1: unloaded
		//			0: ended
		//			1: playing
		//			2: paused
		//			3: buffering
		
	}
	
}
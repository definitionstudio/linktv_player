package com.definition
{
	import flash.display.Sprite;
	import flash.events.*;
	
    import flash.media.Video;
	import flash.media.SoundTransform;
    import flash.net.NetConnection;
    import flash.net.NetStream;
			
			
	public class StdVideoAPI extends Sprite implements VideoAPI {
		
		private var player:Player;					// parent
		private var ready:Boolean = false;
		
		private var qualityLevel:Number = 0;		// set initial quality/videofile
		private var qualityLevels:Array = new Array();
		
		const QUALITY_DEFAULT = 0;
		const QUALITY_HIGH = 1;
		
		private var videoDisplayWidth:Number;
		private var videoDisplayHeight:Number;
		
		public var hidePlayIconOverlay:Boolean = false;
		
		// low-level objects
		private var connection:NetConnection;
		private var stream:NetStream;
		private var video:Video;
		private var progressive:Boolean = false;
		private var videoMeta:Object;
		
		private var videoMetaLoaded:Boolean = false;
		private var videoLoaded:Boolean = false;
		private var videoPlaying:Boolean = false;
		private var videoComplete:Boolean = false;
				
		private var swappingStreams:Boolean = false;
		
		private var currentVolume:Number = 1;		// default to max volume
		
		// video states (YouTube-compatible)
		const STATE_UNSTARTED = -1;
		const STATE_ENDED = 0;
		const STATE_PLAYING = 1;
		const STATE_PAUSED = 2
		const STATE_BUFFERING = 3;
		const STATE_CUED = 5;

		
		// constructor
		public function StdVideoAPI(player:Player, width:Number, height:Number):void {
			
			// set reference
			this.player = player;
			
			videoDisplayWidth = width;
			videoDisplayHeight = height;
			
			// set default quality level
			qualityLevel = QUALITY_DEFAULT;
		}
		
		// init: call after event listeners are assigned
		public function init():void {
			
			// create new video player
			video = new Video(videoDisplayWidth, videoDisplayHeight);
			video.smoothing = true;
			video.visible = false;
			player.videoContainer.addChild(video);	// add to container sprite
			
			// dispatch "unstarted" event (for compatibility with YouTube API)
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_UNSTARTED}));
			
			progressive = (player.mediaServerURL == null) ? true : false;
			
			// connect to Flash Media server
			connection = new NetConnection();
			connection.client = this;
			connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			try {
				connection.connect(player.mediaServerURL);
            } catch(e:ArgumentError) {
				trace(e);				
				// dispatch error event
				dispatchEvent(new CustomEvent("error", false, false, {message:'Error connecting to media server.'}));
			}
		}
		
		private function _connectStream():void {
			
			stream = new NetStream(connection);
			stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			stream.client = this;
			
			// set initial volume
			stream.soundTransform = new SoundTransform(currentVolume);
			
			video.attachNetStream(stream);
			video.visible = true;
			stream.play(player.videoFiles[qualityLevel].path);
			
			videoLoaded = true;
			videoPlaying = true;
			
			// handle start time param
			if(player.videoStart > 0) seekTo(player.videoStart);
						
			trace("playing video", player.videoFiles[qualityLevel].path);
		}
		
		// getters
		
		public function isReady():Boolean {
			return ready;
		}
		
		public function isLoaded():Boolean {
			return videoLoaded;
		}
		
		public function isPlaying():Boolean {
			return videoPlaying;
		}
		
		public function isComplete():Boolean {
			return videoComplete;
		}
		
		public function hasBusyIndicator():Boolean {
			return false;
		}
		
		public function hasPosterImage():Boolean {
			return false;
		}
		
		public function getCurrentTime():Number {
			return (isLoaded()) ? stream.time : player.videoStart;
		}
		
		public function getDuration():Number {
			return player.videoDuration;
		}
		
		public function getVolume():Number {
			return currentVolume;
		}
		
		public function getBytesLoaded():Number {
			return (videoLoaded) ? stream.bytesLoaded : 0;
		}
		
		public function getBytesTotal():Number {
			return (videoLoaded) ? stream.bytesTotal : 0;
		}
		
		public function getQualityLevels():Array {
			qualityLevels = player.videoFiles;
			return qualityLevels;
		}
		
		// playback controls
		
		public function play():void {
			videoPlaying = true;
			if(!videoLoaded) {
				_connectStream();
			} else if(videoComplete) {
				trace('**** VIDEO COMPLETE ****');
				// restart stream
				videoComplete = false;
				stream.play(player.videoFiles[qualityLevel].path);
			} else {
				stream.resume();
				if(progressive) dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PLAYING}));
			}
		}
		
		public function pause():void {
			videoPlaying = false;
			if(videoLoaded) {
				stream.pause();
				if(progressive) dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PAUSED}));
			}
		}
		
		public function mute():void {
			currentVolume = 0;
			if(videoLoaded) stream.soundTransform = new SoundTransform(currentVolume);
		}
		
		public function unMute():void {
			currentVolume = 1;
			if(videoLoaded) stream.soundTransform = new SoundTransform(currentVolume);
		}
		
		public function seekTo(seconds:int, autoPlay:Boolean=false):void {
			if(!videoLoaded) {
				_connectStream();
				if(!autoPlay) pause();
			} else if(autoPlay && !videoPlaying) {
				play();
			}
			stream.seek(seconds);
		}
		
		// resize
		
		public function setSize(width:Number, height:Number):void {
			
			if(videoMetaLoaded) {
				
				videoDisplayWidth = width;
				videoDisplayHeight = height;
			
				var displayAspect:Number = videoDisplayWidth/videoDisplayHeight;
				var videoAspect:Number = videoMeta.width/videoMeta.height;
				var heightAspect:Number = videoMeta.height/videoMeta.width;
				
				var heightAspectOffset:Number = 0.15;
				
				trace("displayAspect: " + displayAspect);
				trace("videoAspect: " + videoAspect);
				
				// fill width (default)
				var playerWidth:Number = width;
				var playerHeight:Number = Math.round(width*heightAspect);
				
				if(displayAspect > (videoAspect+heightAspectOffset)) {
					// fill height
					trace('video size: height priority');
					playerWidth =  Math.round(height*videoAspect);
					playerHeight = height;
				}
					
				video.width = playerWidth;
				video.height = playerHeight;
				
				trace("new player size: " + video.width + "x" + video.height);
				
				repositionVideo();
				
			}
			
		}
		
		public function repositionVideo():void {
			// reset position
			video.x = 0;
			video.y = 0;
			// center video
			if(video.width < videoDisplayWidth) video.x = Math.floor((videoDisplayWidth-video.width)/2);
			if(video.height < videoDisplayHeight) video.y = Math.floor((videoDisplayHeight-video.height)/2);
		}
		
		
		public function setQualityLevel(idx:*):void {
						
			trace("Swap the stream with " + player.videoFiles[idx].path);
			
			swappingStreams = true;
			
			player.showLoading();
			
			// Pause the current stream
			if(videoPlaying) stream.pause();
			
			// reset videoMetaLoaded status before swapping stream
			videoMetaLoaded = false;
			
			if(videoLoaded) {
				// Store the current time
				var seekTime:Number = stream.time;
			
				// Play the new stream
				stream.play(player.videoFiles[idx].path);
				
				// Seek to the saved time in the new stream
				if(progressive) {
					stream.seek(0);
				} else {
					stream.seek(seekTime);
				}
				
				// Make sure the stream is playing (streaming) or paused (progressive)
				if(progressive && !videoPlaying) {
					stream.pause();
				} else if(videoPlaying) {
					stream.resume();
				}
			}
			
			// set current quality level
			qualityLevel = idx;
		}
		
		
		/* ====================== */
		/* = NET EVENT HANDLERS = */
		/* ====================== */
		
		private function netStatusHandler(event:NetStatusEvent):void {
			
			trace('****** NetStatusEvent ******', event.info.code);
			
			switch (event.info.code) {
				
				// NetConnection events
				
				case "NetConnection.Connect.Success":
					trace('READY!!!!');
					ready = true;						// video is ready for playback
					dispatchEvent(new Event("ready"));	// dispatch custom ready event
					dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_CUED}));
					break;
					
				case "NetConnection.Connect.Rejected":

					dispatchEvent(new CustomEvent("error", false, false, {message:'The connection attempt was rejected.'}));
	                break;

	            case "NetConnection.Connect.Failed":

					dispatchEvent(new CustomEvent("error", false, false, {message:'The connection attempt failed.'}));
	                break;
					
				// NetStream events
				
				case "NetStream.Play.StreamNotFound":
				
					videoLoaded = false;
					dispatchEvent(new CustomEvent("error", false, false, {message:'Unable to load video stream (not found).'}));
					break;
					
				case "NetStream.Failed":
				
					videoLoaded = false;
					dispatchEvent(new CustomEvent("error", false, false, {message:'Failed to load video stream.'}));
					break;
					
				case "NetStream.Buffer.Empty":
				
					// dispatch custom event
					dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_BUFFERING}));
					break;
					
				case "NetStream.Buffer.Full":
					
					player.hideLoading();
					
					// dispatch custom event
					if(videoPlaying) dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PLAYING}));
					break;
					
				case "NetStream.Play.Stop":
				
					// video has reached the end (or was unloaded due to a stream quality swap)
					
					// dispatch custom event
					if(!swappingStreams) {
						videoComplete = true;
						videoPlaying = false;
						dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_ENDED}));
					}
					break;
					
				case "NetStream.Play.Start":
				
					if(progressive && swappingStreams) {
						swappingStreams = false;
						player.hideLoading();
					} else if(videoPlaying && !swappingStreams) {
						dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PLAYING}));
					}
					break;
					
				case "NetStream.Play.Reset":	// fires only with streaming source
				
					if(swappingStreams) swappingStreams = false;	// reset quality change status
					break;
					
				case "NetStream.Pause.Notify":	// fires only with streaming source
				
					// dispatch custom event
					dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PAUSED}));
					break;
					
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			// dispatch custom event
			dispatchEvent(new CustomEvent("error", false, false, {message:'Unable to load video stream.'}));
			
			trace("securityErrorHandler: " + event);
		}
		
		private function asyncErrorHandler(event:AsyncErrorEvent):void {
			// ignore AsyncErrorEvent events.
		}
		
				
		/* =================================== */
		/* = NETSTREAM CLIENT EVENT HANDLERS = */
		/* =================================== */
		
		public function onMetaData(info:Object):void {
			
			// onMetaData is called on every seek action
			
			if(!videoMetaLoaded) {
				trace("onMetaData: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
				
				videoMeta = info;
				videoMetaLoaded = true;
				
				// reset video duration & redraw controls
				if(videoMeta.duration != undefined && videoMeta.duration > 0 && videoMeta.duration != player.videoDuration) {
					player.videoDuration = videoMeta.duration;
					player.controls.redraw();
				}
				trace('videoDuration: ' + player.videoDuration);
				
				// redraw controls to reflect new metadata
				player.resizePlayer();
			}
		}
		
		public function onCuePoint(info:Object):void {
			trace("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);
		}
		
		public function onPlayStatus( p_evt:Object ):void
		{
			trace( "*** " + p_evt.type + " " + p_evt.info + " " + p_evt.info.code );
			if ( p_evt.info.code == "NetStream.Play.Complete" )
			{
				//dispatchEvent( p_evt );
			}
		}
		
		
		/* ======================================= */
		/* = NETCONNECTION CLIENT EVENT HANDLERS = */
		/* ======================================= */
		
		public function onBWCheck(info:Object):Number 
		{
			return 0;
		}
			
		public function onBWDone():void 
		{
			trace("onBWDone");
		}
		
	}
	
}
package com.definition
{
	import flash.events.*;
	import flash.utils.*;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.Shape;
	import flash.geom.Rectangle;	// for scrubber drag bounds
	import flash.geom.ColorTransform;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.text.AntiAliasType;
	import flash.display.Bitmap;
    import flash.display.BitmapData;
	import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import com.definition.Player;
	import com.definition.ToolTip;
	
	public class Controls extends Sprite {
		
		private var player:Player;				// parent
		
		// sprites
		private var controls:Sprite;				// container
		private var segmentControls:Sprite;		// container
		
		// symbols (in library)
		private var bPlay:buttonPlay = new buttonPlay();
		private var bPause:buttonPause = new buttonPause();
		private var bInfo:buttonBarInfo = new buttonBarInfo();
		private var bMute:buttonMute = new buttonMute();
		private var bUnMute:buttonUnMute = new buttonUnMute();
		private var bHqOff:buttonHqOff = new buttonHqOff();
		private var bHqOn:buttonHqOn = new buttonHqOn();
		private var bScaleUp:buttonScaleUp = new buttonScaleUp();
		private var bScaleDown:buttonScaleDown = new buttonScaleDown();
		private var bFullScreen:buttonFullScreen = new buttonFullScreen();
		private var bExitFullScreen:buttonExitFullScreen = new buttonExitFullScreen();
		private var scrubber:scrubberMC = new scrubberMC();
		private var segmentHover:segmentInfo = new segmentInfo();
		//private var segmentThumbMask:thumbnailMask = new thumbnailMask();
		
		// dynamic progress bar container sprites
		private var barBackground:Sprite = new Sprite();
		private var barLoad:Sprite = new Sprite();
		private var barProgress:Sprite = new Sprite();		
		
		// tooltip
		private var tooltip:ToolTip;	// sprite
		
		// settings
		private var controlsHeight:Number = 36;
		private var controlsAutoHide:Boolean = true;
		private var controlsAutoHideDelay:Number = 3000;		// ms
		private var progressBarHeight:Number = 8;
		private var segmentControlsHeight:Number = 10;
		
		// status vars
		private var controlsWidth:Number;
		private var controlsMode:String = 'default';
		private var controlsDrawn:Boolean = false;
		
		private var controlsAutoHideStart:Number;
		private var controlsAutoHideTween:Tween;
		private var controlsAnimatingOut:Boolean = false;
		private var controlsAnimatingIn:Boolean = false;
		private var controlsPositionY:Number;
		private var controlsDrawOpen:Boolean = false;
		private var segmentsInitialized:Boolean = false;
		private var scrubbing:Boolean = false;
		
		// timer
		private var controlsHideTimer:Timer = new Timer(500);		// in ms
		
		
		// constructor
		public function Controls(player:Player) {
			
			trace('Controls _CONSTRUCT_');
			
			this.player = player;
			
			trace('player:', player);
			
			// init auto-hide timer listener
			controlsHideTimer.addEventListener(TimerEvent.TIMER, timerHandler);
			
		}
		
		public function draw(mode:String):void {
			
			trace('controls.draw()');
			
			// set vars
			if(mode) controlsMode = mode;
			controlsWidth = player.stage.stageWidth;
			
			if(controlsDrawn) _reset();

			controls = new Sprite();
						
			// init video segments UI
			_initSegments();
			
			var yOffset:Number = segmentControls.height;
			var buttonWidth:Number = bPlay.width;

			// setup progress bars and scrubber
			
			var barBackgroundShape:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.progressBarTrackColor),
				alpha: player.settings.progressBarTrackOpacity,
				width: controlsWidth,
				height: progressBarHeight});
			barBackground.addChild(barBackgroundShape);
			barBackground.y = yOffset;
			barBackground.addEventListener(MouseEvent.CLICK, progressBarClick);
			controls.addChild(barBackground);
			
			var barLoadShape:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.progressBarLoadColor),
				alpha: 1,
				width: 1,
				height: progressBarHeight});
			barLoad.addChild(barLoadShape);
			barLoad.y = yOffset;
			barLoad.addEventListener(MouseEvent.CLICK, progressBarClick);
			controls.addChild(barLoad);
			
			var barProgressShape:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.progressBarColor),
				alpha: 1,
				width: 1,
				height: progressBarHeight});
			barProgress.addChild(barProgressShape);
			barProgress.y = yOffset;
			barProgress.addEventListener(MouseEvent.CLICK, progressBarClick);
			controls.addChild(barProgress);
			
			scrubber.y = yOffset;
			scrubber.buttonMode = true;
			scrubber.addEventListener(MouseEvent.MOUSE_DOWN, scrubberMouseDown);		// scrubber mouseup handled by stage
			controls.addChild(scrubber);
			
			yOffset += barBackground.height;
			
			// attach button bar (background)
			var controlsBg:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.controlsBgColor),
				alpha: player.settings.controlsBgOpacity,
				width: controlsWidth,
				height: controlsHeight});
			
			controlsBg.y = yOffset;
			controlsBg.x = 0;
			controls.addChild(controlsBg);
			
			
			// ##### right-aligned controls
			
			// play
			bPlay.y = yOffset;
			bPlay.buttonMode = true;
			bPlay.visible = (player.video.isPlaying()) ? false : true;
			controls.addChild(bPlay);
			bPlay.toolTipText = "Play";
			bPlay.addEventListener(MouseEvent.CLICK, playButtonClick);
			
			// pause
			bPause.y = yOffset;
			bPause.buttonMode = true;
			bPause.visible = (player.video.isPlaying()) ? true : false;
			controls.addChild(bPause);
			bPause.toolTipText = "Pause";
			bPause.addEventListener(MouseEvent.CLICK, pauseButtonClick);
			
			
			// ##### left-aligned controls (create in reverse order)
			
			var leftIndex:Number = 1;
			
			// MUTE
			
			bMute.y = yOffset;
			bMute.x = controlsWidth-(leftIndex*buttonWidth);
			bMute.buttonMode = true;
			bMute.visible = (player.video.getVolume() > 0) ? true : false;
			bMute.toolTipText = "Mute";
			bMute.addEventListener(MouseEvent.CLICK, muteButtonClick);
			controls.addChild(bMute);
			
			bUnMute.y = yOffset;
			bUnMute.x = controlsWidth-(leftIndex*buttonWidth);
			bUnMute.buttonMode = true;
			bUnMute.visible = (player.video.getVolume() > 0) ? false : true;
			bUnMute.toolTipText = "Unmute";
			bUnMute.addEventListener(MouseEvent.CLICK, unMuteButtonClick);
			controls.addChild(bUnMute);
			
			leftIndex++;
			
			// QUALITY
			
			var videoQualityLevels:Array = player.video.getQualityLevels();		// TODO: implement multi-qulity selector
			
			if(videoQualityLevels.length > 1) {
				
				bHqOff.y = yOffset;
				bHqOff.x = controlsWidth-(leftIndex*buttonWidth);
				bHqOff.buttonMode = true;
				bHqOff.visible = (player.isHighQuality) ? false : true;
				bHqOff.toolTipText = "View High Quality";
				bHqOff.addEventListener(MouseEvent.CLICK, hqOffButtonClick);
				controls.addChild(bHqOff);
				
				bHqOn.y = yOffset;
				bHqOn.x = controlsWidth-(leftIndex*buttonWidth);
				bHqOn.buttonMode = true;
				bHqOn.visible = (player.isHighQuality) ? true : false;
				bHqOn.toolTipText = "View Standard Quality";
				bHqOn.addEventListener(MouseEvent.CLICK, hqOnButtonClick);
				controls.addChild(bHqOn);
				
				leftIndex++;
				
			}
			
			// Player SIZE
			
			if(player.resizeEnabled && controlsMode != 'fullscreen' && !player.embeddedMode && player.externalEventHandler != null) {
				
				bScaleUp.y = yOffset;
				bScaleUp.x = controlsWidth-(leftIndex*buttonWidth);
				bScaleUp.buttonMode = true;
				bScaleUp.visible = (player.isLargeSize) ? false : true;
				bScaleUp.toolTipText = "Expand Player";
				bScaleUp.addEventListener(MouseEvent.CLICK, scaleUpButtonClick);
				controls.addChild(bScaleUp);
				
				bScaleDown.y = yOffset;
				bScaleDown.x = controlsWidth-(leftIndex*buttonWidth);
				bScaleDown.buttonMode = true;
				bScaleDown.visible = (player.isLargeSize) ? true : false;
				bScaleDown.toolTipText = "Resize Player";
				bScaleDown.addEventListener(MouseEvent.CLICK, scaleDownButtonClick);
				controls.addChild(bScaleDown);
				
				leftIndex++;
			}
			
			// FULLSCREEN
			
			if(player.fullscreenEnabled) {
				
				bFullScreen.y = yOffset;
				bFullScreen.x = controlsWidth-(leftIndex*buttonWidth);
				bFullScreen.buttonMode = true;
				bFullScreen.visible = (controlsMode == 'fullscreen') ? false : true;
				bFullScreen.toolTipText = "Fullscreen";
				bFullScreen.addEventListener(MouseEvent.CLICK, fullScreenButtonClick);
				controls.addChild(bFullScreen);
			
				bExitFullScreen.y = yOffset;
				bExitFullScreen.x = controlsWidth-(leftIndex*buttonWidth);
				bExitFullScreen.buttonMode = true;
				bExitFullScreen.visible = (controlsMode == 'fullscreen') ? true : false;
				bExitFullScreen.toolTipText = "Exit Fullscreen";
				bExitFullScreen.addEventListener(MouseEvent.CLICK, exitFullScreenButtonClick);
				controls.addChild(bExitFullScreen);
			
				leftIndex++;
			}
			
			// ###
			
			// assign mouse over/out handlers
			var buttons:Array = [bPlay,bPause,bMute,bUnMute,bHqOff,bHqOn,bScaleUp,bScaleDown,bFullScreen,bExitFullScreen];
			for each(var b:MovieClip in buttons) {
				b.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				b.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			}
			
			// ###
			
			// info text
			bInfo.y = yOffset;
			bInfo.x = bPlay.width;
			
			bInfo.timeDisplay.x = controlsWidth-(leftIndex*buttonWidth) - bInfo.timeDisplay.width - 10;
			bInfo.timeDisplay.defaultTextFormat = player.uiTF;
			bInfo.timeDisplay.embedFonts = true;
			bInfo.timeDisplay.antiAliasType = AntiAliasType.ADVANCED;
			bInfo.timeDisplay.text = Utilities.formatTime(player.video.getCurrentTime()) + ' / ' + Utilities.formatTime(player.videoDuration);
			
			bInfo.videoTitle.width = bInfo.timeDisplay.x - 20;
			bInfo.videoTitle.defaultTextFormat = player.uiTF;
			bInfo.videoTitle.embedFonts = true;
			bInfo.videoTitle.antiAliasType = AntiAliasType.ADVANCED;
			bInfo.videoTitle.text = player.videoTitle;
			
			bInfo.segmentTitle.width = bInfo.timeDisplay.x - 20;
			bInfo.segmentTitle.defaultTextFormat = player.uiTF;
			bInfo.segmentTitle.embedFonts = true;
			bInfo.segmentTitle.antiAliasType = AntiAliasType.ADVANCED;
			bInfo.segmentTitle.text = 'Now watching: ';
			try {
				if(player.videoSegments[player.currentVideoSegment].title) bInfo.segmentTitle.appendText(player.videoSegments[player.currentVideoSegment].title);
			} catch (error:Error) {
				trace("Segment title not present: Skipping");
			}
			
			
			controls.addChild(bInfo);
			
			// ###

			// add controls to stage (hidden)
			controlsPositionY = player.stage.stageHeight - controls.height;		// open position (store for animations)
			controls.y = (controlsDrawOpen) ? controlsPositionY : player.stage.stageHeight;
			player.addChild(controls);
			
			// ###
			
			// start controls autohide timer
			controlsAutoHideStart = getTimer();
			controlsHideTimer.start();
			
			// set status var
			controlsDrawn = true;
		}
		
		private function _initSegments():void {
			
			if(segmentsInitialized) return;		// local
			
			segmentControls = new Sprite();
			
			var segmentGap:int = 2;
			
			if(player.videoSegments.length > 1 && player.videoDuration > 0) {		// fix for divide by zero when duration = 0
			
				trace('drawing segments UI: ' + player.videoSegments.length + ' segments');
			
				for (var i:Number = 0; i<player.videoSegments.length; i++) {
					
					var segment:Object = player.videoSegments[i];
					var segmentBoxX:uint = Math.floor((segment.time/player.videoDuration)*controlsWidth);
										
					var nextSegmentTime:uint = player.videoDuration;		// default to last segment, which will stretch to end
					if(i < (player.videoSegments.length-1)) nextSegmentTime = player.videoSegments[i+1].time;
					
					var nextSegmentX:uint = Math.floor((nextSegmentTime/player.videoDuration)*controlsWidth);
					
					var segmentBoxWidth:Number = nextSegmentX - segmentBoxX;
					if(i < (player.videoSegments.length-1)) segmentBoxWidth -= segmentGap;
					
					var segmentSprite:Sprite = new Sprite();
					segmentSprite.name = "segment-" + i;
					segmentSprite.x = segmentBoxX;
					
					var segmentColor:String = (i == player.currentVideoSegment) ? player.settings.segmentNavActiveColor : player.settings.segmentNavColor;
					var box:Shape = Utilities.drawBox({
						color: Utilities.convertHexColor(segmentColor),
						alpha: player.settings.segmentNavOpacity,
						width: segmentBoxWidth,
						height: segmentControlsHeight});
						
					segmentSprite.addChild(box);
					
					// setup event listeners
					segmentSprite.addEventListener(MouseEvent.MOUSE_OVER, segmentMouseOver);
					segmentSprite.addEventListener(MouseEvent.MOUSE_OUT, segmentMouseOut);
					segmentSprite.addEventListener(MouseEvent.CLICK, segmentClick);
					
					// save reference
					segment.sprite = segmentSprite;
					segmentSprite.buttonMode = true;
					
					segmentControls.addChild(segmentSprite);
				}
				
				controls.addChild(segmentControls);
				
			}
			
			segmentsInitialized = true;
			
		}
		
		public function redraw(mode:String = null):void {	// synonym for draw
			trace('controls.redraw');
			draw(mode);
		}
		
		private function _reset():void {
			player.removeChild(controls);
			segmentsInitialized = false;
			controlsAnimatingOut = false;
			controlsAnimatingIn = false;
			controlsDrawOpen = (controls.y == controlsPositionY || controlsAnimatingIn) ? true : false;
			controlsHideTimer.stop();
			controlsDrawn = false;
		}
		
		public function isScrubbing():Boolean {
			return scrubbing;
		}
		
		public function getScrubPosition():Number {
			return scrubber.x;
		}
		
		public function updateProgress():void {
			
			var currentVideoTime = player.video.getCurrentTime();
			
			// update scrubber
			scrubber.x = currentVideoTime * controlsWidth / player.videoDuration;
			
			// update progress bars
			barLoad.width = player.video.getBytesLoaded() * controlsWidth / player.video.getBytesTotal();
			barProgress.width = scrubber.x + 5;
			
			// update time display
			bInfo.timeDisplay.text = Utilities.formatTime(currentVideoTime) + ' / ' + Utilities.formatTime(player.videoDuration);
					
		}
		
		public function updateActiveSegment(prevSegmentId:Number, newSegmentId:Number):void {
			
			// update box color & display
			var prevBox:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.segmentNavColor),
				alpha: player.settings.segmentNavOpacity,
				width:player.videoSegments[prevSegmentId].sprite.width, 
				height:player.videoSegments[prevSegmentId].sprite.height});
				
			player.videoSegments[prevSegmentId].sprite.removeChildAt(0);
			player.videoSegments[prevSegmentId].sprite.addChild(prevBox);
			
			var newBox:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(player.settings.segmentNavActiveColor),
				alpha: player.settings.segmentNavOpacity,
				width:player.videoSegments[newSegmentId].sprite.width, 
				height:player.videoSegments[newSegmentId].sprite.height});
				
			player.videoSegments[newSegmentId].sprite.removeChildAt(0);
			player.videoSegments[newSegmentId].sprite.addChild(newBox);
			
			if(player.videoSegments[newSegmentId].title) {
				bInfo.segmentTitle.text = "Now watching: " + player.videoSegments[newSegmentId].title;
			} else {
				bInfo.segmentTitle.text = "Now watching: Segment " + (newSegmentId+1);
			}
			
		}
		
		// update play/pause button display
		public function updatePlayState(playing:Boolean) {
			if(playing) {
				bPause.visible	= true;
				bPlay.visible = false;
			} else {
				bPause.visible	= false;
				bPlay.visible = true;
			}
		}
		
		/* ========================= */
		/* = BUTTON EVENT HANDLERS = */
		/* ========================= */
		
		private function mouseOverHandler(e:MouseEvent):void {
			// show tooltip
			tooltip = new ToolTip({
							x: e.currentTarget.x,
							y: e.currentTarget.y,
							text: e.currentTarget.toolTipText, 
							color: Utilities.convertHexColor(player.settings.tooltipBgColor),
							alpha: player.settings.tooltipBgOpacity,
							textFormat: player.tooltipTF});
			controls.addChild(tooltip);
		}
		
		private function mouseOutHandler(e:MouseEvent):void {
			try {
				controls.removeChild(tooltip);
			} catch (error:Error) {
				trace("tooltip not present");
			}
		}
		
		public function stopScrubbing():void {		// called from stage (player)
			scrubbing = false;
			scrubber.stopDrag();
		}
		
		private function playButtonClick(e:MouseEvent):void {
			player.video.play();
		}
		
		private function pauseButtonClick(e:MouseEvent):void {
			player.video.pause();
		}
		
		private function progressBarClick(e:MouseEvent):void {
			player.videoStart = 0;	// reset start time
			player.video.seekTo(Math.round(player.stage.mouseX * player.videoDuration / player.stage.stageWidth));
		}
		
		private function scrubberMouseDown(e:MouseEvent):void {
			// init scrub
			player.startScrub();
			// set status flag
			scrubbing = true;
			// start drag
			scrubber.startDrag(false, new Rectangle(0, e.target.y, controlsWidth, 0));
		}
		
		private function muteButtonClick(e:MouseEvent):void {
			player.video.mute();
			bMute.visible	= false;
			bUnMute.visible = true;
		}
		
		private function unMuteButtonClick(e:MouseEvent):void {
			player.video.unMute();
			bMute.visible	= true;
			bUnMute.visible = false;
		}
		
		private function hqOffButtonClick(e:MouseEvent):void {		// TODO: support variable quality levels
			player.isHighQuality = true;	// for button tracking
			
			// swap streams
			player.video.setQualityLevel(player.video.QUALITY_HIGH);
			
			bHqOff.visible	= false;
			bHqOn.visible = true;
		}
		
		private function hqOnButtonClick(e:MouseEvent):void {		// TODO: support variable quality levels
			player.isHighQuality = false;	// for button tracking
			
			// swap streams
			player.video.setQualityLevel(player.video.QUALITY_DEFAULT);
			
			bHqOff.visible	= true;
			bHqOn.visible = false;
		}
		
		private function scaleUpButtonClick(e:MouseEvent):void {
			player.triggerExternalEvent( { type:'scaleUp' } );		// controls redraw is triggered by stage resize event
			player.isLargeSize = true;
			
			bScaleUp.visible	= false;
			bScaleDown.visible = true;
		}
		
		private function scaleDownButtonClick(e:MouseEvent):void {
			player.triggerExternalEvent( { type:'scaleDown' } );	// controls redraw is triggered by stage resize event
			player.isLargeSize = false;
			
			bScaleUp.visible	= true;
			bScaleDown.visible = false;
		}
		
		private function fullScreenButtonClick(e:MouseEvent):void {
			player.stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		
		private function exitFullScreenButtonClick(e:MouseEvent):void {
			player.stage.displayState = StageDisplayState.NORMAL;
		}
				
		private function segmentMouseOver(e:MouseEvent):void {
			if(controlsAnimatingOut) return;
			var parts:Array = e.target.name.split('-');
			var segmentId:Number = parts[1];
			var segment:Object = player.videoSegments[segmentId];
			
			// swap boxes
			var segmentColor:String = (segmentId == player.currentVideoSegment) ? player.settings.segmentNavActiveColor : player.settings.segmentNavColor;
			var newBox:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(segmentColor),
				alpha: player.settings.segmentNavActiveOpacity,
				width: e.target.width,
				height: e.target.height});
				
			e.target.removeChildAt(0);
			e.target.addChild(newBox);
			
			// do hover overlay
			segmentHover = new segmentInfo();			
			segmentHover.x = e.target.x;
			segmentHover.y = e.target.y-segmentHover.height;
			
			// apply color
			var bgColorTransform:ColorTransform = new ColorTransform();
			bgColorTransform.color = Utilities.convertHexColor(player.settings.segmentInfoBgColor);
			segmentHover.bg.transform.colorTransform = bgColorTransform;
			
			// adjust opacity
			segmentHover.bg.alpha = Number(player.settings.segmentInfoBgOpacity);
			
			var padding:Number = 7;
			var segmentThumbPresent:Boolean = false;
			var segmentThumbMask:thumbnailMask = new thumbnailMask();
			
			// thumbnail
			if(player.videoSegmentThumbs[segmentId] != undefined || player.posterImgLoaded) {
				var thumbImgSrc:Bitmap = (player.videoSegmentThumbs[segmentId] != undefined) ? player.videoSegmentThumbs[segmentId] : player.posterImg;
				var thumbImg:Bitmap = new Bitmap(thumbImgSrc.bitmapData.clone());
				var imgAspect:Number = thumbImg.width/thumbImg.height;
				
				segmentHover.addChild(segmentThumbMask);

				thumbImg.smoothing = true;
				thumbImg.height = segmentThumbMask.height;
				thumbImg.width = Math.ceil(segmentThumbMask.height*imgAspect);
				thumbImg.x = padding-Math.floor((thumbImg.width-segmentThumbMask.width)/2);		// center
				thumbImg.y = padding;
				thumbImg.mask = segmentThumbMask;
				segmentThumbMask.x = padding;
				segmentThumbMask.y = padding;
				
				segmentHover.addChild(thumbImg);
				segmentThumbPresent = true;
			}
			
			// title text
			var segmentTitle:TextField = new TextField();
			segmentTitle.x = segmentThumbPresent ? segmentThumbMask.x+segmentThumbMask.width+padding : padding;
			segmentTitle.y = padding;
			segmentTitle.width = segmentThumbPresent ? segmentHover.width-(segmentThumbMask.x+segmentThumbMask.width)-(padding*4) : segmentHover.width-(padding*2);
			segmentTitle.height = segmentHover.height - (padding*2);
			segmentTitle.selectable = false;
			segmentTitle.wordWrap = true;
			segmentTitle.embedFonts = true;
			segmentTitle.antiAliasType = AntiAliasType.ADVANCED;
			segmentTitle.defaultTextFormat = player.segmentTitleTF;
			segmentTitle.text = "Chapter " + (segmentId+1) + "\n" + segment.title;
			segmentHover.addChild(segmentTitle);
			
			segmentHover.alpha = 0;
			controls.addChild(segmentHover);
			
			// correct offscreen position
			if((segmentHover.x + segmentHover.width) > player.stage.stageWidth) {
				segmentHover.x = e.target.x - segmentHover.bg.width;
				// flip horizontal
				segmentHover.bg.scaleX *= -1;
				segmentHover.bg.x = segmentHover.bg.width;
			}
			
			// fade-in
			try {
				var tween:Tween = new Tween(segmentHover, "alpha", null, segmentHover.alpha, 1, 0.15, true);
			} catch (error:Error) {}
		}
		
		private function segmentMouseOut(e:MouseEvent):void {
			var parts:Array = e.target.name.split('-');
			var segmentId:Number = parts[1];
						
			// swap boxes
			var segmentColor:String = (segmentId == player.currentVideoSegment) ? player.settings.segmentNavActiveColor : player.settings.segmentNavColor;
			var newBox:Shape = Utilities.drawBox({
				color: Utilities.convertHexColor(segmentColor),
				alpha: player.settings.segmentNavOpacity,
				width: e.target.width,
				height: e.target.height});
				
			e.target.removeChildAt(0);
			e.target.addChild(newBox);
			
			// remove hover overlay
			try {
				if(segmentHover.parent != null) controls.removeChild(segmentHover);
			} catch(error:Error) {}
		}
		
		private function segmentClick(e:MouseEvent):void {
			var parts:Array = e.target.name.split('-');
			var segmentId:Number = parts[1];
			var segment:Object = player.videoSegments[segmentId];
			// seek to start time
			player.video.seekTo(segment.time);
		}

		
		/* ================== */
		/* = TIMER HANDLERS = */
		/* ================== */
		
		public function resetTimer() {
			controlsAutoHideStart = getTimer();
		}

		public function timerHandler(e:TimerEvent):void {
			try {
				var timePassed = getTimer();
				if (timePassed-controlsAutoHideStart >= controlsAutoHideDelay) {
					controlsAnimatingIn = false;
					if(!controlsAnimatingOut && !scrubbing) {
						controlsAutoHideTween = new Tween(controls, "y", Regular.easeOut, controls.y, player.stage.stageHeight, 1, true);
						controlsAnimatingOut = true;
					}
				} else if(!player.mouseOffStage) {
					controlsAnimatingOut = false;
					if(controls.y != controlsPositionY && !controlsAnimatingIn) {
						controlsAutoHideTween = new Tween(controls, "y", Strong.easeOut, controls.y, controlsPositionY, 1, true);
						controlsAnimatingIn = true;
					}
				}
				
			} catch (error:Error) {
				trace(error);
			}
		}

		
	}
	
	
}
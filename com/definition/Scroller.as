package com.definition
{
	
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.events.*;
	import flash.utils.*;
		
	public class Scroller extends Sprite {
		
		private var target:TextField;
		private var scrubber:Sprite = new Sprite();
		private var track:Sprite = new Sprite();
		
		private var scrolling:Boolean = false;
		
		public function setTarget(t:TextField):void {
			target = t;
			
			var pct = target.height/target.textHeight;
			if(pct >= 1) return
			
			target.scrollV = 1;	// scroll to top
			
			// draw track
			var trackShape:Shape = Utilities.drawBox({color: 0xCCCCCC, alpha: 0.3, width: 6, height: target.height});
			track.addChild(trackShape);
			
			var scrubberShape = Utilities.drawBox({color: 0xCCCCCC, alpha: 0.7, width: 6, height: Math.floor(track.height*pct)});
			scrubber.addChild(scrubberShape);
			
			this.x = target.x + target.width + 10;
			this.y = target.y;
			
			scrubber.addEventListener(MouseEvent.MOUSE_DOWN, scrubberDownHandler);
			scrubber.buttonMode = true;
			
			addChild(track);
			addChild(scrubber);
		}
		
		public function isScrolling():Boolean {
			return scrolling;
		}
		
		// event handlers
		
		private function scrubberDownHandler(e:MouseEvent):void {
			
			scrolling = true;
			scrubber.startDrag(false, new Rectangle(0, 0, 0, track.height-scrubber.height));
			parent.addEventListener(MouseEvent.MOUSE_MOVE, scrubberMoveHandler);
			parent.addEventListener(MouseEvent.MOUSE_UP, scrubberUpHandler);
			
		}
		
		private function scrubberMoveHandler(e:MouseEvent):void {
			
			var scrollPct:Number = scrubber.y/(track.height-scrubber.height);
			trace(scrollPct);
			
			target.scrollV = Math.round(target.maxScrollV*scrollPct);			
		}
		
		private function scrubberUpHandler(e:MouseEvent):void {
			
			parent.removeEventListener(MouseEvent.MOUSE_MOVE, scrubberMoveHandler);
			parent.removeEventListener(MouseEvent.MOUSE_UP, scrubberUpHandler);
			
			setTimeout(function():void { scrolling = false; }, 50);					// delay so stage mouse up fires first
			
		}
		
		

		
	}
	
}
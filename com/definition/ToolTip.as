package com.definition
{
	import flash.utils.*;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flash.geom.Rectangle;	// for bounds
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;		
	
	public class ToolTip extends Sprite {
		
		private var params:Object;
		private var delay:uint = 1000;
		private var verticalPad:uint = 2;
		private var horizontalPad:uint = 6;
		private var timeout:uint;
		
		// constructor
		public function ToolTip(params:Object) {		// params: text, color, alpha, textFormat
			
			this.params = params;
			this.alpha = 0;
			timeout = setTimeout(draw, delay);
			
		}
		
		public function draw():void {
			
			try {
			
				var tf:TextField = new TextField();
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.mouseEnabled = false;
				tf.x = horizontalPad;
				tf.y = verticalPad;
				tf.defaultTextFormat = params.textFormat;
				tf.embedFonts = true;
				tf.antiAliasType = AntiAliasType.ADVANCED;
				tf.text = params.text;
				
				var bg:Shape = Utilities.drawBox({color:params.color, alpha:params.alpha, width:tf.width+(horizontalPad*2), height:tf.height+(verticalPad*2)});
				
				// add elements
				addChild(bg);
				addChild(tf);
				
				// position
				this.x = params.x;
				this.y = params.y-this.height;
				this.mouseEnabled = false;
				
				// correct offscreen position
				var bounds:Rectangle = this.getBounds(stage);
				
				if(bounds.right > stage.stageWidth) {
					this.x -= Math.ceil(bounds.right-stage.stageWidth);
				}
				
				// fade-in
				var tween:Tween = new Tween(this, "alpha", null, this.alpha, 1, 0.1, true);
				
			} catch(error:Error) {
				//trace('tooltip draw error. probably removed parent before draw timeout.');
			}
			
		}
		
	}
	
}
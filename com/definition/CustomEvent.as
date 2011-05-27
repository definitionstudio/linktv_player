package com.definition
{
	import flash.events.Event;
	
	public class CustomEvent extends Event {
		
		public var data:Object;
		
		public function CustomEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, data:Object = null) {
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		public override function clone():Event {
			return new CustomEvent(type, bubbles, cancelable, data);
        }
		
		public override function toString():String { 
			return formatToString("CustomEvent", "type", "bubbles", "cancelable", "eventPhase", "data"); 
		}
		
	}
	
}
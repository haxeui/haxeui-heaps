package haxe.ui.backend;

import haxe.ui.events.UIEvent;

@:allow(haxe.ui.backend.ComponentImpl)
@:allow(haxe.ui.backend.ScreenImpl)
class EventImpl extends EventBase {
    private var _originalEvent:hxd.Event;

    public override function cancel() {
        if (_originalEvent != null) {
            _originalEvent.cancel = true;
            _originalEvent.propagate = false;
        }
    }
    
    private override function postClone(event:UIEvent) {
        event._originalEvent = this._originalEvent;
    }
}

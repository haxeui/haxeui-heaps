package haxe.ui.backend;
import haxe.ui.events.UIEvent;

@:allow(haxe.ui.backend.ComponentBase)
@:allow(haxe.ui.backend.ScreenBase)
class EventBase {
    private var _originalEvent:hxd.Event;

    public function new() {
    }
    
    public function cancel() {
        if (_originalEvent != null) {
            _originalEvent.cancel = true;
            _originalEvent.propagate = false;
        }
    }
    
    private function postClone(event:UIEvent) {
        event._originalEvent = this._originalEvent;
    }
}
package haxe.ui.backend.heaps;

import haxe.ui.events.KeyboardEvent;
import hxd.Window;

class KeyboardHelper {
    private static var _hasOnEvent:Bool = false;
    
    private static var _callbacks:Map<String, Array<KeyboardEvent->Void>> = new Map<String, Array<KeyboardEvent->Void>>();
    
    public static function notify(event:String, callback:KeyboardEvent->Void) {
        switch (event) {
            case KeyboardEvent.KEY_DOWN:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
            case KeyboardEvent.KEY_UP:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
            case KeyboardEvent.KEY_PRESS:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
        }
        
        var list = _callbacks.get(event);
        if (list == null) {
            list = new Array<KeyboardEvent->Void>();
            _callbacks.set(event, list);
        }
        
        list.push(callback);
    }

    public static function remove(event:String, callback:KeyboardEvent->Void) {
        var list = _callbacks.get(event);
        if (list != null) {
            list.remove(callback);
            if (list.length == 0) {
                _callbacks.remove(event);
            }
        }
    }

    private static function onEvent(e:hxd.Event) {
        switch (e.kind) {
            case EKeyDown:
                onKeyDown(e);
            case EKeyUp:
                onKeyUp(e);
            case _:        
        }
    }

    private static function onKeyDown(e:hxd.Event) {
        var list = _callbacks.get(KeyboardEvent.KEY_DOWN);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        var event = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
        @:privateAccess event._originalEvent = e;
        event.keyCode = e.keyCode;
        for (l in list) {
            l(event);
        }
    }

    private static function onKeyUp(e:hxd.Event) {
        var list = _callbacks.get(KeyboardEvent.KEY_UP);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        var event = new KeyboardEvent(KeyboardEvent.KEY_UP);
        @:privateAccess event._originalEvent = e;
        event.keyCode = e.keyCode;
        for (l in list) {
            l(event);
        }
    }
}
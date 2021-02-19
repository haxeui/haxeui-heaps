package haxe.ui.backend.heaps;

import haxe.ui.events.MouseEvent;
import hxd.Window;

class MouseHelper {
    public static var currentMouseX:Float = 0;
    public static var currentMouseY:Float = 0;
    
    private static var _hasOnEvent:Bool = false;
    
    private static var _callbacks:Map<String, Array<MouseEvent->Void>> = new Map<String, Array<MouseEvent->Void>>();
    
    public static function notify(event:String, callback:MouseEvent->Void) {
        switch (event) {
            case MouseEvent.MOUSE_DOWN:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
            case MouseEvent.MOUSE_UP:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
            case MouseEvent.MOUSE_MOVE:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
            case MouseEvent.MOUSE_WHEEL:
                if (_hasOnEvent == false) {
                    Window.getInstance().addEventTarget(onEvent);
                    _hasOnEvent = true;
                }
        }
        
        var list = _callbacks.get(event);
        if (list == null) {
            list = new Array<MouseEvent->Void>();
            _callbacks.set(event, list);
        }
        
        list.push(callback);
    }
    
    public static function remove(event:String, callback:MouseEvent->Void) {
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
            case EMove:
                onMouseMove(e);
            case EPush:    
                onMouseDown(e);
            case ERelease | EReleaseOutside:
                onMouseUp(e);
            case EWheel:
                onMouseWheel(e);
            case _:    
        }
    }
    
    private static function onMouseMove(e:hxd.Event) {
        currentMouseX = Window.getInstance().mouseX / Toolkit.scaleX;
        currentMouseY = Window.getInstance().mouseY / Toolkit.scaleY;
        
        var list = _callbacks.get(MouseEvent.MOUSE_MOVE);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        var event = new MouseEvent(MouseEvent.MOUSE_MOVE);
        event.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
        event.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseDown(e:hxd.Event) {
        var list = _callbacks.get(MouseEvent.MOUSE_DOWN);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_DOWN);
        event.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
        event.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
        event.data = e.button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseUp(e:hxd.Event) {
        var list = _callbacks.get(MouseEvent.MOUSE_UP);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_UP);
        event.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
        event.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
        event.data = e.button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseWheel(e:hxd.Event) {
        var list = _callbacks.get(MouseEvent.MOUSE_WHEEL);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        event.delta = e.wheelDelta;
        for (l in list) {
            l(event);
        }
    }
}
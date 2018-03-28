package haxe.ui.backend;

import hxd.Event.EventKind;
import haxe.ui.core.KeyboardEvent;
import haxe.ui.core.MouseEvent;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.backend.heaps.HeapsApp;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.DialogButton;
import haxe.ui.core.Component;
import haxe.ui.core.UIEvent;

@:access(h2d.Layers)
class ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;

    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
    }

    public function init() {
        var s2d:h2d.Scene = HeapsApp.getInstance().s2d;
        if (!Lambda.empty(_mapping)) {
            s2d.addEventListener(__onEvent);
            _mainEventAdded = true;
        }
    }

    public var focus:Component;

    private var _options:ToolkitOptions;
    public var options(get, set):ToolkitOptions;
    private function get_options():ToolkitOptions {
        return _options;
    }
    private function set_options(value:ToolkitOptions):ToolkitOptions {
        _options = value;
        return value;
    }

    public var width(get, null):Float;
    private function get_width():Float {
        return HeapsApp.getInstance().s2d.width;
    }

    public var height(get, null):Float;
    private function get_height():Float {
        return HeapsApp.getInstance().s2d.height;
    }

    public var dpi(get, null):Float;
    private function get_dpi():Float {
        return hxd.System.screenDPI;
    }

    public function addComponent(component:Component) {
        HeapsApp.getInstance().s2d.addChildAt(component.sprite, 0);//TODO
    }

    public function removeComponent(component:Component) {
        HeapsApp.getInstance().s2d.removeChild(component.sprite);
    }

    private function handleSetComponentIndex(child:Component, index:Int) {
        HeapsApp.getInstance().s2d.addChildAt(child.sprite, index);
    }

    //***********************************************************************************************************
    // Dialogs
    //***********************************************************************************************************
    public function messageDialog(message:String, title:String = null, options:Dynamic = null, callback:DialogButton->Void = null):Dialog {
        return null;
    }

    public function showDialog(content:Component, options:Dynamic = null, callback:DialogButton->Void = null):Dialog {
        return null;
    }

    public function hideDialog(dialog:Dialog):Bool {
        return false;
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private var _mouseDownButton : Int = -1;
    private var _mainEventAdded:Bool;

    private function supportsEvent(type:String):Bool {
        return EventMapper.HAXEUI_TO_HEAPS.get(type) != null;
    }

    private function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
                | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.CLICK
                | KeyboardEvent.KEY_DOWN | KeyboardEvent.KEY_UP:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    var s2d:h2d.Scene = HeapsApp.getInstance().s2d;
                    if (s2d != null && !_mainEventAdded) {
                        s2d.addEventListener(__onEvent);
                        _mainEventAdded = true;
                    }
                }
        }
    }

    private function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
                | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.CLICK
                | KeyboardEvent.KEY_DOWN | KeyboardEvent.KEY_UP:
                _mapping.remove(type);
                var s2d:h2d.Scene = HeapsApp.getInstance().s2d;
                if (s2d != null && Lambda.empty(_mapping)) {
                    s2d.removeEventListener(__onEvent);
                    _mainEventAdded = false;
                }
        }
    }

    private function __onEvent(event:hxd.Event) {
        var type:String = switch (event.kind) {
            case EMove:
                MouseEvent.MOUSE_MOVE;
            case EPush:
                if (event.button == 0) {
                    _mouseDownButton = event.button;
                    MouseEvent.MOUSE_DOWN;
                } else {
                    null;
                }
            case ERelease | EReleaseOutside:
                var tmp = _mouseDownButton;
                _mouseDownButton = -1;
                if (event.button == 0) {
                    if (tmp == event.button) {
                        __dispatchEventType(MouseEvent.MOUSE_UP, event);
                        MouseEvent.CLICK;
                    } else {
                        null;
                    }
                } else {
                    null;
                }
            case EOver:
                MouseEvent.MOUSE_OVER;
            case EOut:
                _mouseDownButton = -1;
                MouseEvent.MOUSE_OUT;
            case EWheel:
                MouseEvent.MOUSE_WHEEL;
            case EKeyUp:
                KeyboardEvent.KEY_UP;
            case EKeyDown:
                KeyboardEvent.KEY_DOWN;
            default:
                null;
        }

        if (type != null) {
            __dispatchEventType(type, event);
        }
    }

    private function __dispatchEventType(type:String, originalEvent:hxd.Event) {
        var fn = _mapping.get(type);
        if (fn != null) {
            if (type == KeyboardEvent.KEY_DOWN || type == KeyboardEvent.KEY_UP) {
                var keyboardEvent = new KeyboardEvent(type);
                keyboardEvent._originalEvent = originalEvent;
                keyboardEvent.keyCode = originalEvent.keyCode;
                keyboardEvent.shiftKey = hxd.Key.isDown(hxd.Key.SHIFT);
                fn(keyboardEvent);
            } else {
                var mouseEvent = new MouseEvent(type);
                mouseEvent._originalEvent = originalEvent;
                var s2d:h2d.Scene = HeapsApp.getInstance().s2d;
                mouseEvent.screenX = s2d.mouseX / Toolkit.scaleX;//event.relX / Toolkit.scaleX;
                mouseEvent.screenY = s2d.mouseY / Toolkit.scaleY;//event.relY / Toolkit.scaleY;
                mouseEvent.buttonDown = false; //event.button;  //TODO
                mouseEvent.delta = originalEvent.wheelDelta;
                fn(mouseEvent);
            }
        }
    }
}
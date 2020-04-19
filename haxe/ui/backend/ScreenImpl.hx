package haxe.ui.backend;

import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import hxd.App;

class ScreenImpl extends ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;

    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
        MainLoop.add(BackendImpl.update);
    }
    
    public var app(get, null):App;
    private function get_app():App {
        if (app == null && options != null) {
            app = options.app;
        }

        if (app == null) {
            throw "no app specified in toolkit options";
        }
        
        return app;
    }
    
    private override function get_width():Float {
        return app.s2d.width;
    }

    private override function get_height():Float {
        return app.s2d.height;
    }

    private override function get_dpi():Float {
        return hxd.System.screenDPI;
    }
    
    public override function addComponent(component:Component):Component {
        _topLevelComponents.push(component);
        if (_removedComponents.indexOf(component) != -1) {
            _removedComponents.remove(component);
            component.visible = true;
        } else {
            app.s2d.addChildAt(component, 0);
        }
        resizeComponent(component);
        return component;
    }

    private var _removedComponents:Array<Component> = []; // TODO: probably ill conceived
    public override function removeComponent(component:Component):Component {
        _topLevelComponents.remove(component);
        if (_removedComponents.indexOf(component) == -1) {
            //app.s2d.removeChild(component);
            _removedComponents.push(component);
            component.visible = false;
        }
        return component;
    }

    private override function handleSetComponentIndex(component:Component, index:Int) {
        app.s2d.addChildAt(component, index);
        resizeComponent(component);
    }
    
    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private var _eventHandlerAdded:Bool = false;
    private function addEventHandler() {
        if (_eventHandlerAdded == true) {
            return;
        }
        
        var s2d:h2d.Scene = app.s2d;
        if (s2d != null && !_eventHandlerAdded) {
            s2d.addEventListener(_onEvent);
            _eventHandlerAdded = true;
        }
    }
    
    private var _currentOverComponent:Component = null;
    private var _buttonDown:Int = -1;
    private function _onEvent(event:hxd.Event) {
        var components = [];
        var s2d:h2d.Scene = app.s2d;
        for (c in _topLevelComponents) {
            var t = c.findComponentsUnderPoint(s2d.mouseX / Toolkit.scaleX, s2d.mouseY / Toolkit.scaleY);
            components = components.concat(t);
        }

        components.reverse();
        switch (event.kind) {
            case EMove:
                var overComponent = null;
                for (c in components) {
                    if (c.hasEventListener(MouseEvent.MOUSE_OVER)) {
                        overComponent = c;
                        c.handleMouseEvent(MouseEvent.MOUSE_OVER, event);
                        break;
                    }
                }
                
                if (_currentOverComponent != null && _currentOverComponent != overComponent) {
                    _currentOverComponent.handleMouseEvent(MouseEvent.MOUSE_OUT, event);
                }
                
                _currentOverComponent = overComponent;
                handleMouseEvent(MouseEvent.MOUSE_MOVE, event);
                
            case EPush:
                _buttonDown = event.button;
                handleMouseEvent(MouseEvent.MOUSE_DOWN, event);
                
            case ERelease | EReleaseOutside:
                _buttonDown = -1;
                handleMouseEvent(MouseEvent.MOUSE_UP, event);

            case EWheel:
                for (c in components) {
                    if (c.hasEventListener(MouseEvent.MOUSE_WHEEL)) {
                        c.handleMouseEvent(MouseEvent.MOUSE_WHEEL, event);
                        break;
                    }
                }
                
            default:    
        }
    }
    
    private function handleMouseEvent(type:String, event:hxd.Event) {
        if (_mapping.exists(type)) {
            var fn = _mapping.get(type);
            var mouseEvent = new MouseEvent(type);
            mouseEvent._originalEvent = event;
            var s2d:h2d.Scene = app.s2d;
            mouseEvent.screenX = s2d.mouseX / Toolkit.scaleX;
            mouseEvent.screenY = s2d.mouseY / Toolkit.scaleY;
            if (_buttonDown != -1) {
                mouseEvent.buttonDown = true;
            }
            mouseEvent.delta = event.wheelDelta;
            fn(mouseEvent);
            
            event.propagate = false;
            event.cancel = true;
        }
    }
    
    private override function supportsEvent(type:String):Bool {
        return EventMapper.HAXEUI_TO_HEAPS.get(type) != null;
    }

    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
                | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.CLICK
                /* | KeyboardEvent.KEY_DOWN | KeyboardEvent.KEY_UP */ :
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                }
        }
    }
}
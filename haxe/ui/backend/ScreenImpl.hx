package haxe.ui.backend;

import h2d.Scene;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import hxd.Window;

class ScreenImpl extends ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;

    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
    }
    
    private var _rootScene:Scene = null;
    public var rootScene(get, set):Scene;
    private function get_rootScene():Scene {
        if (_rootScene != null) {
            return _rootScene;
        }
        
        if (options == null) {
            return null;
        }
        
        return options.rootScene;
    }
    private function set_rootScene(value:Scene):Scene {
        _rootScene = value;
        return value;
    }
    
    private override function set_options(value:ToolkitOptions):ToolkitOptions {
        super.set_options(value);
        if (value.manualUpdate == null || value.manualUpdate == false) {
            MainLoop.add(BackendImpl.update);
        }
        return value;
    }
    
    private override function get_width():Float {
        return Window.getInstance().width;
    }

    private override function get_height():Float {
        return Window.getInstance().height;
    }

    private override function get_dpi():Float {
        return hxd.System.screenDPI;
    }
    
    public override function addComponent(component:Component):Component {
        _topLevelComponents.push(component);
        if (_removedComponents.indexOf(component) != -1) {
            if (rootScene == null) {
                trace("WARNING: trying to add a component to a null rootScene. Either set Screen.instance.rootScene or specify one in Toolkit.init");
                return component;
            }
            _removedComponents.remove(component);
            //rootScene.addChildAt(component, 0);
            component.visible = true;
        } else {
            if (rootScene == null) {
                trace("WARNING: trying to add a component to a null rootScene. Either set Screen.instance.rootScene or specify one in Toolkit.init");
                return component;
            }
            rootScene.addChildAt(component, 0);
        }
        resizeComponent(component);
        return component;
    }

    private var _removedComponents:Array<Component> = []; // TODO: probably ill conceived
    public override function removeComponent(component:Component):Component {
        _topLevelComponents.remove(component);
        if (_removedComponents.indexOf(component) == -1) {
            if (rootScene == null) {
                trace("WARNING: trying to remove a component to a null rootScene. Either set Screen.instance.rootScene or specify one in Toolkit.init");
                return component;
            }
            //rootScene.removeChild(component);
            _removedComponents.push(component);
            component.visible = false;
        }
        return component;
    }

    private override function handleSetComponentIndex(component:Component, index:Int) {
        if (rootScene == null) {
            trace("WARNING: trying to set a component index in a null rootScene. Either set Screen.instance.rootScene or specify one in Toolkit.init");
            return;
        }
        rootScene.addChildAt(component, index);
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
        if (!_eventHandlerAdded) {
            Window.getInstance().addEventTarget(_onEvent);
            _eventHandlerAdded = true;
        }
    }
    
    private var _currentOverComponent:Component = null;
    private var _buttonDown:Int = -1;
    private function _onEvent(event:hxd.Event) {
        var components = [];
        for (c in _topLevelComponents) {
            var t = c.findComponentsUnderPoint(Window.getInstance().mouseX / Toolkit.scaleX, Window.getInstance().mouseY / Toolkit.scaleY);
            components = components.concat(t);
        }

        components.reverse();
        switch (event.kind) {
            case EMove:
                var overComponent = null;
                for (c in components) {
                    if (c.hasEventListener(MouseEvent.MOUSE_OVER)) {
                        overComponent = c;
                        break;
                    }
                }
                
                switch [_currentOverComponent, overComponent] {
                    case [null, null]: // nothing to do
                    case [null, current]:
                        current.handleMouseEvent(MouseEvent.MOUSE_OVER, event);
                    case [last, null]:
                        last.handleMouseEvent(MouseEvent.MOUSE_OUT, event);
                    case [last, current] if(last == current):
                        current.handleMouseEvent(MouseEvent.MOUSE_MOVE, event);
                    case [last, current]:
                        last.handleMouseEvent(MouseEvent.MOUSE_OUT, event);
                        current.handleMouseEvent(MouseEvent.MOUSE_OVER, event);
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
            mouseEvent.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
            mouseEvent.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
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
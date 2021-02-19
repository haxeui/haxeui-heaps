package haxe.ui.backend;

import h2d.Scene;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.backend.heaps.MouseHelper;
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
    private override function supportsEvent(type:String):Bool {
        return EventMapper.HAXEUI_TO_HEAPS.get(type) != null;
    }

    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_DOWN:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }
                
            case MouseEvent.MOUSE_UP:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                }
        }
    }
    
    private function __onMouseMove(event:MouseEvent) {
        var fn = _mapping.get(MouseEvent.MOUSE_MOVE);
        if (fn != null) {
            var mouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
            mouseEvent.screenX = event.screenX;
            mouseEvent.screenY = event.screenY;
            mouseEvent.buttonDown = event.data;
            fn(mouseEvent);
        }
    }
    
    private function __onMouseDown(event:MouseEvent) {
        var fn = _mapping.get(MouseEvent.MOUSE_DOWN);
        if (fn != null) {
            var mouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN);
            mouseEvent.screenX = event.screenX;
            mouseEvent.screenY = event.screenY;
            mouseEvent.buttonDown = event.data;
            fn(mouseEvent);
        }
    }
    
    private function __onMouseUp(event:MouseEvent) {
        var fn = _mapping.get(MouseEvent.MOUSE_UP);
        if (fn != null) {
            var mouseEvent = new MouseEvent(MouseEvent.MOUSE_UP);
            mouseEvent.screenX = event.screenX;
            mouseEvent.screenY = event.screenY;
            mouseEvent.buttonDown = event.data;
            fn(mouseEvent);
        }
    }
}
package haxe.ui.backend;

import h2d.Interactive;
import h2d.Mask;
import h2d.Object;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.Screen;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import hxd.Window;

class ComponentImpl extends ComponentBase { 
    private var _eventMap:Map<String, UIEvent->Void>;
    
    static inline var INDEX_OFFSET = 1; // offset everything because 0th-child is always the style graphics container

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
        addChild(new Object()); // style graphics container
        cast(this, Component).ready();
    }

    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left == null || top == null || left < 0 || top < 0) {
            return;
        }
        
        left = Std.int(left);
        top = Std.int(top);
        
        if (_mask == null) {
            this.x = left;
            this.y = top;
        } else {
            _mask.x = left;
            _mask.y = top;
        }
        if (_interactive != null) {
            _interactive.x = 0;
            _interactive.y = 0;
        }
    }
    
    private override function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        StyleHelper.apply(this, style, w, h);
        if (_interactive != null) {
            _interactive.width = w;
            _interactive.height = h;
        }
    }
    
    private override function handleVisibility(show:Bool) {
        visible = show;
    }
    
    private var _mask:Mask = null;
    private override function handleClipRect(value:Rectangle) {
        if (value != null) {
            if (_mask == null) {
                _mask = new Mask(Std.int(value.width), Std.int(value.height), this.parentComponent);
                _mask.addChild(this);
            }
            this.x = -value.left + 1;
            this.y = -value.top;
            _mask.x = left - 1;
            _mask.y = top;
            _mask.width = Std.int(value.width) + 1;
            _mask.height = Std.int(value.height);
        } else if (_mask != null) {
            _mask = null;
        }
    }
    
    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    public override function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            super.createTextDisplay(text);
            addChild(_textDisplay.sprite);
        }
        
        return _textDisplay;
    }

    public override function createTextInput(text:String = null):TextInput {
        if (_textInput == null) {
            super.createTextInput(text);
            addChild(_textInput.sprite);
        }
        
        return _textInput;
    }
    
    //***********************************************************************************************************
    // Image related
    //***********************************************************************************************************
    public override function createImageDisplay():ImageDisplay {
        if (_imageDisplay == null) {
            super.createImageDisplay();
            addChild(_imageDisplay.sprite);
        }
        
        return _imageDisplay;
    }
    
    public override function removeImageDisplay() {
        if (_imageDisplay != null) {
            removeChild(_imageDisplay.sprite);
            _imageDisplay.dispose();
            _imageDisplay = null;
        }
    }
    
    //***********************************************************************************************************
    // Display tree
    //***********************************************************************************************************
    
    private override function handleSetComponentIndex(child:Component, index:Int) {
        addChildAt(child, index + INDEX_OFFSET);
    }

    private override function handleAddComponent(child:Component):Component {
        addChild(child);
        return child;
    }

    private override function handleAddComponentAt(child:Component, index:Int):Component {
        addChildAt(child, index + INDEX_OFFSET);
        return child;
    }

    private override function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        removeChild(child);
        //TODO - dispose
        return child;
    }

    private override function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        var child = _children[index + INDEX_OFFSET];
        if (child != null) {
            removeChild(child);

            //TODO - dispose
        }
        return child;
    }
    
    private override function applyStyle(style:Style) {
        /*
        if (style.cursor != null && style.cursor == "pointer") {
            cursor = Cursor.Button;
        } else if (cursor != hxd.Cursor.Default) {
            cursor = Cursor.Default;
        }
        */

        if (style.filter != null) {
            //TODO
        } else {
            filter = null;
        }

        if (style.hidden != null) {
            visible = !style.hidden;
        }

        if (style.opacity != null) {
            alpha = style.opacity;
        }
    }
    
    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    public function hasEventListener(type:String):Bool {
        return _eventMap.exists(type);
    }
    
    public function handleMouseEvent(type:String, event:hxd.Event) {
        if (_eventMap.exists(type) == false) {
            return;
        }
        
        var fn = _eventMap.get(type);
        if (fn != null) {
            var mouseEvent = new MouseEvent(type);
            mouseEvent._originalEvent = event;
            mouseEvent.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
            mouseEvent.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
            if (_buttonDown != -1) {
                mouseEvent.buttonDown = true;
            }
            mouseEvent.delta = -event.wheelDelta;
            fn(mouseEvent);
        }
    }
    
    @:access(haxe.ui.core.Screen)
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        Screen.instance.addEventHandler();
        
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT | MouseEvent.MOUSE_WHEEL:
                if (!_eventMap.exists(type)) {
                    _eventMap.set(type, listener);
                }
            case MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.CLICK:
                if (!_eventMap.exists(type)) {
                    interactive = true;
                    _eventMap.set(type, listener);
                    Reflect.setProperty(_interactive, EventMapper.HAXEUI_TO_HEAPS.get(type), __onMouseEvent.bind(_, type));
                }
        }
    }

    private var _buttonDown:Int = -1;
    private function __onMouseEvent(event:hxd.Event, type:String) {
        switch (event.kind) {
            case EPush:
                _buttonDown = event.button;
                if (this.parentComponent == null) {
                    event.propagate = false;
                }
            case ERelease | EReleaseOutside:
                _buttonDown = -1;
            default:    
        }

        var fn = _eventMap.get(type);
        if (fn != null) {
            var mouseEvent = new MouseEvent(type);
            mouseEvent._originalEvent = event;
            mouseEvent.screenX = Window.getInstance().mouseX / Toolkit.scaleX;
            mouseEvent.screenY = Window.getInstance().mouseY / Toolkit.scaleY;
            if (_buttonDown != -1) {
                mouseEvent.buttonDown = true;
            }
            mouseEvent.delta = event.wheelDelta;
            fn(mouseEvent);
        }
    }
    
    //***********************************************************************************************************
    // Helpers
    //***********************************************************************************************************
    private var _interactive:Interactive = null;
    private var interactive(get, set):Bool;
    private function get_interactive():Bool {
        return (_interactive != null);
    }
    private function set_interactive(value:Bool):Bool {
        if (value == false) {
            _interactive = null;
        } else {
            if (_interactive == null) {
                _interactive = new Interactive(width, height, this);
                _interactive.propagateEvents = true;
                _interactive.enableRightButton = true;
                _interactive.x = 0;
                _interactive.y = 0;
            }
        }
        return value;
    }
}
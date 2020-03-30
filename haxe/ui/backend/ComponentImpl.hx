package haxe.ui.backend;

import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.backend.heaps.UISprite;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.Screen;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import hxd.Cursor;

class ComponentImpl extends ComponentBase {
    private var _eventMap:Map<String, UIEvent->Void>;

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
    }

    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left != null) {
            x = left;
        }

        if (top != null) {
            y = top;
        }
    }

    private override function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        setSize(w, h);
        StyleHelper.apply(this, style, x, y, __width, __height);
    }

    private override function handleClipRect(value:Rectangle) {
        clipRect = value;
    }

    private override function handleVisibility(show:Bool) {
        visible = show;
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

    //***********************************************************************************************************
    // Display tree
    //***********************************************************************************************************
    private override function handleSetComponentIndex(child:Component, index:Int) {
        addChildAt(child, index);
    }

    private override function handleAddComponent(child:Component):Component {
        addChild(child);
        return child;
    }

    private override function handleAddComponentAt(child:Component, index:Int):Component {
        addChildAt(child, index);
        return child;
    }

    private override function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        removeChild(child);
        //TODO - dispose
        return child;
    }

    private override function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        var child = cast(this, Component)._children[index];
        if (child != null) {
            removeChild(child);

            //TODO - dispose
        }
        return child;
    }

    private override function applyStyle(style:Style) {
        if (style.cursor != null && style.cursor == "pointer") {
            cursor = Cursor.Button;
        } else if (cursor != hxd.Cursor.Default) {
            cursor = Cursor.Default;
        }

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
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
                | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.MOUSE_WHEEL
                | MouseEvent.CLICK:
                if (!_eventMap.exists(type)) {
                    interactive = true;
                    _eventMap.set(type, listener);
                    Reflect.setProperty(interactiveObj, EventMapper.HAXEUI_TO_HEAPS.get(type), __onMouseEvent.bind(_, type));
                }
        }
    }

    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
            | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.MOUSE_WHEEL
            | MouseEvent.CLICK:
                _eventMap.remove(type);
                Reflect.setProperty(interactiveObj, EventMapper.HAXEUI_TO_HEAPS.get(type), null);
        }

        if (Lambda.empty(_eventMap)) {
            interactive = false;
        }
    }

    private function __onMouseEvent(event:hxd.Event, type:String) {
        trace("mouse event: " + type);
        var fn = _eventMap.get(type);
        if (fn != null) {
            var mouseEvent = new MouseEvent(type);
            mouseEvent._originalEvent = event;
            var s2d:h2d.Scene = Screen.instance.app.s2d;
            mouseEvent.screenX = s2d.mouseX / Toolkit.scaleX;//event.relX / Toolkit.scaleX;
            mouseEvent.screenY = s2d.mouseY / Toolkit.scaleY;//event.relY / Toolkit.scaleY;
            mouseEvent.buttonDown = false; //event.button;  //TODO
            mouseEvent.delta = event.wheelDelta;
            fn(mouseEvent);
        }
    }
}
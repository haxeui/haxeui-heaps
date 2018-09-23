package haxe.ui.backend;

import haxe.ui.core.Screen;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.backend.heaps.HeapsApp;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.backend.heaps.UISprite;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.MouseEvent;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.core.UIEvent;
import haxe.ui.styles.Style;
import haxe.ui.util.Rectangle;
import hxd.Cursor;

class ComponentBase extends UISprite {
    private var _eventMap:Map<String, UIEvent->Void>;

    public function new() {
        super(null);
        _eventMap = new Map<String, UIEvent->Void>();
    }

    public function handleCreate(native:Bool) {
    }

    private function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left != null) {
            x = left;
        }

        if (top != null) {
            y = top;
        }
    }

    private function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        setSize(w, h);
        StyleHelper.apply(this, style, x, y, __width, __height);
    }

    private function handleReady() {
    }

    private function handleClipRect(value:Rectangle) {
        clipRect = value;
    }

    public function handlePreReposition() {
    }

    public function handlePostReposition() {
    }

    private function handleVisibility(show:Bool) {
        visible = show;
    }

    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    private var _textDisplay:TextDisplay;
    public function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            _textDisplay = new TextDisplay();
            _textDisplay.parentComponent = cast(this, Component);
            addChild(_textDisplay.sprite);
        }
        if (text != null) {
            _textDisplay.text = text;
        }
        return _textDisplay;
    }

    public function getTextDisplay():TextDisplay {
        return createTextDisplay();
    }

    public function hasTextDisplay():Bool {
        return (_textDisplay != null);
    }

    private var _textInput:TextInput;
    public function createTextInput(text:String = null):TextInput {
        if (_textInput == null) {
            _textInput = new TextInput();
            _textInput.parentComponent = cast(this, Component);
            addChild(_textInput.sprite);
        }
        if (text != null) {
            _textInput.text = text;
        }
        return _textInput;
    }

    public function getTextInput():TextInput {
        return createTextInput();
    }

    public function hasTextInput():Bool {
        return (_textInput != null);
    }

    //***********************************************************************************************************
    // Image related
    //***********************************************************************************************************
    private var _imageDisplay:ImageDisplay;
    public function createImageDisplay():ImageDisplay {
        if (_imageDisplay == null) {
            _imageDisplay = new ImageDisplay();
            addChild(_imageDisplay.sprite);
        }
        return _imageDisplay;
    }

    public function getImageDisplay():ImageDisplay {
        return createImageDisplay();
    }

    public function hasImageDisplay():Bool {
        return (_imageDisplay != null);
    }

    public function removeImageDisplay() {
        if (_imageDisplay != null) {
            _imageDisplay = null;
        }
    }

    //***********************************************************************************************************
    // Display tree
    //***********************************************************************************************************
    private function handleSetComponentIndex(child:Component, index:Int) {
        addChildAt(child, index);
    }

    private function handleAddComponent(child:Component):Component {
        addChild(child);
        return child;
    }

    private function handleAddComponentAt(child:Component, index:Int):Component {
        addChildAt(child, index);
        return child;
    }

    private function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        removeChild(child);
        //TODO - dispose
        return child;
    }

    private function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        var child = cast(this, Component)._children[index];
        if (child != null) {
            removeChild(child);

            //TODO - dispose
        }
        return child;
    }

    private function applyStyle(style:Style) {
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
    private function mapEvent(type:String, listener:UIEvent->Void) {
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

    private function unmapEvent(type:String, listener:UIEvent->Void) {
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
package haxe.ui.backend;

import haxe.ui.backend.heaps.HeapsApp;
import haxe.ui.backend.heaps.EventMapper;
import haxe.ui.core.MouseEvent;
import haxe.ui.backend.heaps.UISprite;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.core.UIEvent;
import haxe.ui.core.Component;
import haxe.ui.styles.Style;
import haxe.ui.util.Rectangle;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;

class ComponentBase {
    public var sprite(default, null):UISprite;
    private var _eventMap:Map<String, UIEvent->Void>;

    public function new() {
        _eventMap = new Map<String, UIEvent->Void>();
    }

    public function handleCreate(native:Bool) {
//        sprite = new h2d.Interactive(0, 0);
        sprite = new UISprite(null);
    }

    private function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left != null) {
            sprite.x = left;
        }

        if (top != null) {
            sprite.y = top;
        }
    }

    private function handleSize(width:Null<Float>, height:Null<Float>, style:Style) {
        if (width == null || height == null || width <= 0 || height <= 0) {
            return;
        }

        sprite.width = width;
        sprite.height = height;

//        var c:Component = cast(this, Component);
//        var parent:ComponentBase = c.parentComponent;
//        var borderSize:Int = parent.borderSize;
        StyleHelper.apply(sprite, style, sprite.x, sprite.y, width, height);
    }

    private function handleReady() {
    }

    private function handleClipRect(value:Rectangle) {
        sprite.clipRect = value;
    }

    public function handlePreReposition() {
    }

    public function handlePostReposition() {
    }

    private function handleVisibility(show:Bool) {
        sprite.visible = show;
    }

    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    private var _textDisplay:TextDisplay;
    public function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            _textDisplay = new TextDisplay();
            sprite.addChild(_textDisplay.sprite);
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
            sprite.addChild(_textInput.sprite);
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
            sprite.addChild(_imageDisplay.sprite);
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
        sprite.addChildAt(child.sprite, index);
    }

    private function handleAddComponent(child:Component):Component {
        sprite.addChild(child.sprite);
        return child;
    }

    private function handleAddComponentAt(child:Component, index:Int):Component {
        sprite.addChildAt(child.sprite, index);
        return child;
    }

    private function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        sprite.removeChild(child.sprite);
        //TODO - dispose
        return child;
    }

    private function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        var child = cast(this, Component)._children[index];
        if (child != null) {
            sprite.removeChild(child.sprite);

            //TODO - dispose
        }
        return child;
    }

    private function applyStyle(style:Style) {
//        if (style.cursor != null) {
            //TODO
//        } else if (sprite.cursor != hxd.Cursor.Default) {
//            sprite.cursor = hxd.Cursor.Default;
//        }

        if (style.filter != null) {
            //TODO
        } else {
            sprite.filter = null;
        }

        if (style.hidden != null) {
            sprite.visible = !style.hidden;
        }

        if (style.opacity != null) {
            sprite.alpha = style.opacity;
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
                    sprite.interactive = true;
                    _eventMap.set(type, listener);
                    Reflect.setProperty(sprite.interactiveObj, EventMapper.HAXEUI_TO_HEAPS.get(type), __onMouseEvent.bind(_, type));
                }
        }
    }

    private function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE | MouseEvent.MOUSE_OVER | MouseEvent.MOUSE_OUT
            | MouseEvent.MOUSE_DOWN | MouseEvent.MOUSE_UP | MouseEvent.MOUSE_WHEEL
            | MouseEvent.CLICK:
                _eventMap.remove(type);
                Reflect.setProperty(sprite.interactiveObj, EventMapper.HAXEUI_TO_HEAPS.get(type), null);
        }

        if (Lambda.empty(_eventMap)) {
            sprite.interactive = false;
        }
    }

    private function __onMouseEvent(event:hxd.Event, type:String) {
        var fn = _eventMap.get(type);
        if (fn != null) {
            var mouseEvent = new MouseEvent(type);
            mouseEvent._originalEvent = event;
            var s2d:h2d.Scene = HeapsApp.getInstance().s2d;
            mouseEvent.screenX = s2d.mouseX / Toolkit.scaleX;//event.relX / Toolkit.scaleX;
            mouseEvent.screenY = s2d.mouseY / Toolkit.scaleY;//event.relY / Toolkit.scaleY;
            mouseEvent.buttonDown = false; //event.button;  //TODO
            mouseEvent.delta = event.wheelDelta;
            fn(mouseEvent);
        }
    }
}
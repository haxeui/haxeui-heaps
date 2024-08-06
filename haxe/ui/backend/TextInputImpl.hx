package haxe.ui.backend;

import h2d.TextInput;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.UIEvent;
import hxd.Event;
import hxd.Key;

class TextInputImpl extends TextDisplayImpl {

    var textInput: TextInput;

    public function new() {
        super();
    }

    private override function createText() {
        textInput = new TextInput(hxd.res.DefaultFont.get());
        textInput.lineBreak = false;
        textInput.onChange = onChange;
        textInput.onClick = function(e) {
            cast(parentComponent, InteractiveComponent).focus = true;
        }
        return textInput;
    }

    // we're actually going to override this function so that it always returns
    // h2d.Text.Align.Left - this is because heaps text input doesnt seem to like
    // center aligned text (or right aligned), for now will simply turn it off
    private override function getAlign(align:String):h2d.Text.Align {
        return h2d.Text.Align.Left;
    }

    public override function focus() {
        Toolkit.callLater(function() {
            textInput.focus();
        });
    }

    public override function blur() {
        @:privateAccess textInput.interactive.blur();
    }

    private function onChange() {
        _text = textInput.text;
        _htmlText = textInput.text;
        
        measureText();
        
        if (_inputData.onChangedCallback != null) {
            _inputData.onChangedCallback();
        }
        
        if (parentComponent != null) {
            parentComponent.dispatch(new UIEvent(UIEvent.CHANGE));
        }
    }

    private override function validateDisplay() {
        super.validateDisplay();
        
        textInput.inputWidth = Math.round(textInput.maxWidth); // clip text input display to text component's width
    }

    private override function resizeFont(fontSizeValue:Int, isBitmap:Bool) {
        var temp = sprite.font.clone();
        if (isBitmap) {
            temp.resizeTo(-fontSizeValue);
        } else {
            if (temp == hxd.res.DefaultFont.get()) {
                temp = hxd.res.DefaultFont.get().clone();
            }
            temp.resizeTo(fontSizeValue);
        }
        sprite.font = temp;
        temp = null;
    }

    private override function validateStyle():Bool {
        var measureTextRequired:Bool = super.validateStyle();

        if ( _inputData.password) {
            trace("TextInput password mode isn't supported in Heaps.");
            _inputData.password = false; 
        }

        if (parentComponent.disabled) {
            textInput.canEdit = false;
        } else {
            textInput.canEdit = true;
        }
        
        return measureTextRequired;
    }
    
    private var _onKeyDown:KeyboardEvent->Void = null;
    public var onKeyDown(null, set):KeyboardEvent->Void;
    private function set_onKeyDown(value:KeyboardEvent->Void):KeyboardEvent->Void {
        _onKeyDown = value;
        if (_onKeyDown == null && _onKeyUp == null && _onKeyPress == null) {
            unregisterInernalEvents();
            return value;
        }
        registerInternalEvents();
        return value;
    }

    private var _onKeyUp:KeyboardEvent->Void = null;
    public var onKeyUp(null, set):KeyboardEvent->Void;
    private function set_onKeyUp(value:KeyboardEvent->Void):KeyboardEvent->Void {
        _onKeyUp = value;
        if (_onKeyDown == null && _onKeyUp == null && _onKeyPress == null) {
            unregisterInernalEvents();
            return value;
        }
        registerInternalEvents();
        return value;
    }

    private var _onKeyPress:KeyboardEvent->Void = null;
    public var onKeyPress(null, set):KeyboardEvent->Void;
    private function set_onKeyPress(value:KeyboardEvent->Void):KeyboardEvent->Void {
        _onKeyPress = value;
        if (_onKeyDown == null && _onKeyUp == null && _onKeyPress == null) {
            unregisterInernalEvents();
            return value;
        }
        registerInternalEvents();
        return value;
    }

    private var _internalEventsRegistered = false;
    private function registerInternalEvents() {
        if (_internalEventsRegistered) {
            return;
        }
        _internalEventsRegistered = true;
        textInput.onKeyDown = onKeyDownInternal;
        textInput.onKeyUp = onKeyUpInternal;
    }

    // heaps doesnt have a keypress event, so we'll hold onto down keys in order to dispatch the press event
    private var _downKeys:Map<Int, Bool> = new Map<Int, Bool>();
    private function unregisterInernalEvents() {
        textInput.onKeyDown = null;
        textInput.onKeyUp = null;
        _internalEventsRegistered = false;
    }

    private function onKeyDownInternal(e:Event) {
        _downKeys.set(e.keyCode, true);
        dispatchEvent(KeyboardEvent.KEY_DOWN, e.keyCode);
    }

    private function onKeyUpInternal(e:Event) {
        var hadDownKey = (_downKeys.exists(e.keyCode) && _downKeys.get(e.keyCode) == true);
        _downKeys.remove(e.keyCode);
        dispatchEvent(KeyboardEvent.KEY_UP, e.keyCode);
        if (hadDownKey) {
            dispatchEvent(KeyboardEvent.KEY_PRESS, e.keyCode);
        }
    }

    private function dispatchEvent(type:String, keyCode:Int) {
        var event = new KeyboardEvent(type);
        event.keyCode = keyCode;
        event.altKey = Key.isDown(Key.ALT);
        event.shiftKey = Key.isDown(Key.SHIFT);
        event.ctrlKey = Key.isDown(Key.CTRL); 
        switch (type) {
            case KeyboardEvent.KEY_DOWN:
                if (_onKeyDown != null) {
                    _onKeyDown(event);
                }
            case KeyboardEvent.KEY_UP:
                if (_onKeyUp != null) {
                    _onKeyUp(event);
                }
            case KeyboardEvent.KEY_PRESS:
                if (_onKeyPress != null) {
                    _onKeyPress(event);
                }
        }
    }
}
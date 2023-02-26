package haxe.ui.backend;

import haxe.ui.events.FocusEvent;
import haxe.ui.core.InteractiveComponent;
import h2d.TextInput;
import haxe.ui.events.UIEvent;

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
    
}
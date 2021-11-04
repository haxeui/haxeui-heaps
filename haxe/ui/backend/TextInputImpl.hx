package haxe.ui.backend;

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
        return textInput;
    }

    public override function focus() {
        textInput.focus();
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
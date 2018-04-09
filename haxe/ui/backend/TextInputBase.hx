package haxe.ui.backend;

import haxe.ui.core.TextInput.TextInputData;

class TextInputBase extends TextDisplayBase {
    private var _inputData:TextInputData = new TextInputData();

    private var _password:Bool;
    private var _hscrollPos:Float;
    private var _vscrollPos:Float;
    
    public function new() {
        super();
    }

    public function hasFocus() {
        cast(sprite, h2d.TextInput).hasFocus();
    }

    public function focus() {
        cast(sprite, h2d.TextInput).focus();
    }

    private override function createText():h2d.Text {
        return new h2d.TextInput(hxd.res.DefaultFont.get());
    }
}

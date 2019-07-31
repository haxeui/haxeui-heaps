package haxe.ui.backend;

import haxe.ui.core.TextInput.TextInputData;

class TextInputImpl extends TextDisplayImpl {
    public function new() {
        super();
    }

    public function hasFocus() {
        cast(sprite, h2d.TextInput).hasFocus();
    }

    public override function focus() {
        cast(sprite, h2d.TextInput).focus();
    }

    public override function blur() {

    }

    private override function createText():h2d.Text {
        return new h2d.TextInput(hxd.res.DefaultFont.get());
    }
}

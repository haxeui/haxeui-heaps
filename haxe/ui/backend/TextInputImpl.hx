package haxe.ui.backend;

import h2d.TextInput;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.UIEvent;
import hxd.Event;
import hxd.Key;

class TextInputImpl extends TextDisplayImpl {

    /**
        The colour selected text is highlighted in.

        Heaps' own default, since this is the same highlight - only drawn behind
        the text rather than through it (see `selectionSprite`).
    **/
    public static var selectionColor:Int = 0x3399FF;

    /**
        The highlight under selected text, drawn BEHIND the text.

        h2d.TextInput draws its own by emitting a tile from the text itself, which
        cannot work for a signed distance field font: the SDF shader is attached
        to the text drawable, so every tile that drawable emits goes through it,
        and the shader ends `textureColor = vec4(1.0, 1.0, 1.0, smoothstep(...))`
        - the tile's colour is discarded and only its coverage survives. The
        highlight therefore arrives painted in the colour of the text, as a solid
        bar over exactly the words it is meant to be showing. Nor is a translucent
        one available instead: coverage is a smoothstep whose smoothing is derived
        from the gradient across the texture, and a flat colour has no gradient,
        so the bar is fully opaque or entirely absent.

        A separate object carries its own shaders and none of them is that one, so
        the highlight is drawn here, from the same measurements h2d.TextInput uses
        for its own. ComponentImpl puts it in the style container, which is drawn
        before the text.
    **/
    public var selectionSprite(default, null):TextSelection;

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
        hideNativeSelection();
        selectionSprite = new TextSelection(textInput);
        return textInput;
    }

    // Whatever heaps would draw for the selection, draw none of it: the tile keeps
    // whatever width draw() gives it per line, but no height covers nothing.
    //
    // Re-applied whenever the style is validated because that is where the font is
    // set, and h2d.Text.set_font builds a fresh selection tile of its own.
    var emptySelection:h2d.Tile = null;
    private function hideNativeSelection() {
        if (emptySelection == null) {
            emptySelection = h2d.Tile.fromColor(0xFFFFFF, 0, 0);
        }
        textInput.selectionTile = emptySelection;
    }

    // we're actually going to override this function so that it always returns
    // h2d.Text.Align.Left - this is because heaps text input doesnt seem to like
    // center aligned text (or right aligned), for now will simply turn it off
    /*private override function getAlign(align:String):h2d.Text.Align {
        return h2d.Text.Align.Left;
    }*/

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

        hideNativeSelection();

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

/**
    The highlight under selected text: a rectangle per wrapped line, drawn behind
    the words rather than emitted by them (see `TextInputImpl.selectionSprite`).

    There is no event for "the selection changed" - a drag of the mouse or a
    shift-arrow moves it with nothing dispatched - so it is checked once a frame
    in `sync`, where heaps offers a look at an object before the frame it is drawn
    in. The check is a compare: the geometry is rebuilt only when the selection,
    the text or the layout has actually moved.
**/
class TextSelection extends h2d.Graphics {

    var input:h2d.TextInput;
    var last:String = null;

    public function new(input:h2d.TextInput) {
        super();
        this.input = input;
    }

    public override function sync(ctx:h2d.RenderContext) {
        refresh();
        super.sync(ctx);
    }

    function refresh() {
        var range = input.selectionRange;
        var now = (range == null) ? "-"
            : range.start + ":" + range.length + ":" + input.text.length + ":" + input.x + ":" + input.y;
        if (now == last) {
            return;
        }
        last = now;

        clear();
        if (range == null || range.length <= 0) {
            return;
        }

        // A sibling of the text rather than a child of it, so it has to take the
        // offset the layout gave the text itself.
        x = input.x;
        y = input.y;

        // The same walk h2d.TextInput does for its own highlight, in the same index
        // space: cursorIndex and selectionRange count the WRAPPED text, breaks
        // included, which is why getSplitLines hands back every line with a '\n'
        // on the end. Turning those into positions in the text itself is what
        // getTextPos is for, and nothing here needs to.
        var lines = @:privateAccess input.getSplitLines();
        var lineHeight = input.font.lineHeight;
        var offset = 0;
        beginFill(TextInputImpl.selectionColor, 1);
        for (i in 0...lines.length) {
            var line = lines[i];
            if (range.start >= offset + line.length || range.start + range.length < offset) {
                offset += line.length;
                continue;
            }
            var from = Std.int(Math.max(0, range.start - offset));
            var count = Std.int(Math.min(line.length - from, range.length + range.start - offset - from));
            var left = input.calcTextWidth(line.substr(0, from));
            var width = input.calcTextWidth(line.substr(from, count));
            // A selection that has taken a line break covers no characters on
            // that line: show the break itself, one caret wide.
            if (width <= 0) {
                width = input.cursorTile.width;
            }
            offset += line.length;
            drawRect(left, i * lineHeight, width, lineHeight);
        }
        endFill();
    }
}

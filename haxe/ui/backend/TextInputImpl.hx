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

    /** The same object as `textInput`, typed for the scrolling it adds. **/
    var scrollableInput: ScrollingTextInput;

    public function new() {
        super();
    }

    private override function createText() {
        scrollableInput = new ScrollingTextInput(hxd.res.DefaultFont.get());
        scrollableInput.onCursorMoved = keepCursorInView;
        textInput = scrollableInput;
        textInput.lineBreak = false;
        textInput.onChange = onChange;
        textInput.onClick = function(e) {
            cast(parentComponent, InteractiveComponent).focus = true;
        }
        textInput.onSubmit = onSubmit;
        hideNativeSelection();
        selectionSprite = new TextSelection(textInput);
        return textInput;
    }

    // h2d.TextInput blurs its Interactive when Enter is pressed in a single line input (and only
    // then calls onSubmit). No other haxeui backend drops focus on Enter, and the FocusManager is
    // never told about that blur, so take the native focus back - unless the KEY_DOWN handler that
    // already ran for this key press moved haxeui focus elsewhere. handleKey ignores all input while
    // cursorIndex < 0, so put the cursor back too (h2d's onBlur reset it).
    private function onSubmit() {
        if (parentComponent == null || cast(parentComponent, InteractiveComponent).focus == false) {
            return;
        }
        textInput.focus();
        textInput.cursorIndex = textInput.getTextLength();
        keepCursorInView();
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
        syncScroll();
        keepCursorInView();

        if (_inputData.onChangedCallback != null) {
            _inputData.onChangedCallback();
        }

        if (parentComponent != null) {
            parentComponent.dispatch(new UIEvent(UIEvent.CHANGE));
        }
    }

    /**
        Layout units per unit of the TEXT's own space.

        The glyphs are baked at DEVICE size and the text sprite stands scaled
        down to match (TextDisplayImpl, which is where the ratio comes from), so
        everything measured off the field — a line height, a caret's offset down
        the text, the width of a run of characters — is in units that much
        bigger than the component around it. Anything handed DOWN to the field
        divides by this; anything read back off it multiplies. At Toolkit scale
        1 every one of those is an identity, which is why none of it showed
        until the editor followed the desktop.
    **/
    private var textScale(get, never):Float;
    private function get_textScale():Float {
        var s = (sprite != null) ? sprite.scaleY : 1;
        return (s > 0) ? s : 1;
    }

    private override function validateData() {
        super.validateData();
        syncScroll();   // the words changed, so how far they reach has too
    }

    private override function validateDisplay() {
        super.validateDisplay();
        if (!textInput.multiline) {
            textInput.inputWidth = Math.round(textInput.maxWidth); // clip text input display to text component's width
        } else {
            // A multiline field is a WINDOW onto its text: h2d.TextInput turns its
            // own clipping and scrolling off when multiline (it expects to stand at
            // full height inside something that scrolls), so the size it has been
            // given is handed down as the view and everything past it is scrolled
            // rather than drawn over whatever the component sits next to.
            //
            // In the TEXT's units (see textScale): the view is a rectangle the
            // field clips its own drawing to, and the field draws in the units
            // its glyphs are baked in. Handed the component's own numbers it
            // showed only 1/scale of every line and 1/scale of the lines.
            scrollableInput.viewWidth = _width / textScale;
            scrollableInput.viewHeight = _height / textScale;
        }
        syncScroll();
    }

    /**
        Keep the scroll range, and the position, in step with the text and with the
        size the component has been given.

        This is what fills in `vscrollMax` and `vscrollPageSize`, which is all a
        TextArea needs to give its scrollbar something to do - the same numbers a
        ScrollView works its own out from: the range is how much text does not fit,
        and the page is the share of it that shows.
    **/
    private function syncScroll() {
        if (scrollableInput == null) {
            return;
        }
        if (!textInput.multiline || _height <= 0) {
            _inputData.vscrollMax = 0;
            _inputData.vscrollPageSize = 0;
            scrollableInput.scrollY = 0;
            applySelectionView();
            return;
        }

        var max = _textHeight - _height;
        if (max < 0) {
            max = 0;
        }
        _inputData.vscrollMax = max;
        _inputData.vscrollPageSize = (max > 0 && _textHeight > 0) ? (_height / _textHeight) * max : 0;

        if (_inputData.vscrollPos > max) {
            _inputData.vscrollPos = max;
        }
        if (_inputData.vscrollPos < 0) {
            _inputData.vscrollPos = 0;
        }
        scrollableInput.scrollY = _inputData.vscrollPos / textScale;
        applySelectionView();
    }

    // The highlight is a separate object, so it scrolls and clips separately too.
    private function applySelectionView() {
        if (selectionSprite == null) {
            return;
        }
        // Both in the TEXT's units, which is what the highlight measures itself
        // in (it walks the field's own lines) and what the scale below draws it
        // at — the scroll it takes is the field's own, already converted.
        selectionSprite.scrollY = (scrollableInput != null) ? scrollableInput.scrollY : 0;
        selectionSprite.viewHeight = textInput.multiline ? _height / textScale : 0;
        // The words are drawn at the text's scale and the bars under them are
        // built from the same measurements, so they are drawn at it too. Set
        // here rather than once, because the font (and with it the ratio) is
        // rebuilt whenever the style is.
        selectionSprite.setScale(textScale);
    }

    /**
        Bring the line the caret is on back into view, and tell the component so
        that its scrollbar follows.

        Heaps has its own answer to this and it does not apply: a multiline
        h2d.TextInput asks its parent CONTAINERS to scroll to the caret
        (`scrollToPos`), which only works when it sits inside an h2d flow.
    **/
    private function keepCursorInView() {
        if (scrollableInput == null || !textInput.multiline || _height <= 0) {
            return;
        }
        if (textInput.cursorIndex < 0) {   // not being edited: leave it where it is
            return;
        }

        // Measured off the FIELD, so in its units; everything they are compared
        // with below (the scroll position, the height, the maximum) is the
        // component's, so they are brought over here rather than each time.
        var line = scrollableInput.cursorLineTop() * textScale;
        var lineHeight = textInput.font.lineHeight * textScale;
        var pos = _inputData.vscrollPos;
        if (line < pos) {
            pos = line;
        } else if (line + lineHeight > pos + _height) {
            pos = line + lineHeight - _height;
        }
        if (pos > _inputData.vscrollMax) {
            pos = _inputData.vscrollMax;
        }
        if (pos < 0) {
            pos = 0;
        }
        if (pos == _inputData.vscrollPos) {
            return;
        }

        _inputData.vscrollPos = pos;
        scrollableInput.scrollY = pos / textScale;
        applySelectionView();
        if (_inputData.onScrollCallback != null) {
            _inputData.onScrollCallback();
        }
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
        if (_textStyle != null) {
            if (_displayData.multiline != textInput.multiline) {
                textInput.multiline = _displayData.multiline;
                measureTextRequired = true;
            }
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

    /** How far down the text the field has been scrolled, and how much of it
        shows - the highlight is a separate object, so it has to be moved and
        clipped separately. Zero height is no window, which is the single-line
        case: everything is drawn where it falls. **/
    public var scrollY:Float = 0;
    public var viewHeight:Float = 0;

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
            : range.start + ":" + range.length + ":" + input.text.length + ":" + input.x + ":" + input.y
              + ":" + scrollY + ":" + viewHeight;
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

            // Scrolled and clipped by hand, since this object is drawn outside
            // the render zone the field clips its own text with.
            var top = i * lineHeight - scrollY;
            var bottom = top + lineHeight;
            if (viewHeight > 0) {
                if (bottom <= 0 || top >= viewHeight) {
                    continue;
                }
                if (top < 0) {
                    top = 0;
                }
                if (bottom > viewHeight) {
                    bottom = viewHeight;
                }
            }
            drawRect(left, top, width, bottom - top);
        }
        endFill();
    }
}

/**
    An h2d.TextInput that can be a WINDOW onto its own text.

    Heaps turns clipping and horizontal scrolling off for a multiline field
    (`if( multiline ) { iw = -1; scrollX = 0; }` in its draw) because it expects
    such a field to stand at its full height inside something that scrolls. A
    HaxeUI TextArea is not that: it is a fixed box with scrollbars of its own, so
    the field has to hold the view itself - otherwise its text is drawn straight
    over whatever the component happens to sit next to, and its scrollbars have
    nothing to move.

    So: a view size, a vertical offset applied the same way heaps applies its own
    horizontal one, and a render zone to keep the words inside the box.
**/
private class ScrollingTextInput extends h2d.TextInput {

    /** How far down the text the view has been moved, in pixels. **/
    public var scrollY:Float = 0;

    /** The size of the window onto the text. Zero or less is no window at all,
        which is the single-line case and heaps' own behaviour. **/
    public var viewWidth:Float = 0;
    public var viewHeight:Float = 0;

    /** Called whenever a key has moved the caret - typing arrives through
        `onChange` instead. **/
    public var onCursorMoved:Void->Void = null;

    public function new(font:h2d.Font, ?parent:h2d.Object) {
        super(font, parent);
    }

    /** Where the caret's line begins, measured down the text. **/
    public function cursorLineTop():Float {
        return getCursorYOffset();
    }

    override function onCursorChange() {
        super.onCursorChange();
        if (onCursorMoved != null) {
            onCursorMoved();
        }
    }

    // A click lands on the line that is SHOWN there, not the one that would be
    // there unscrolled.
    override function textPos(x:Float, y:Float) {
        return super.textPos(x, y + scrollY);
    }

    // The clickable area is the window, not the whole text: without this a field
    // scrolled to its last line would still be taking clicks from the components
    // below it.
    override function syncInteract() {
        super.syncInteract();
        if (viewHeight > 0 && interactive != null && interactive.height > viewHeight) {
            interactive.height = viewHeight;
        }
    }

    override function draw(ctx:h2d.RenderContext) {
        if (!multiline || viewHeight <= 0 || viewWidth <= 0) {
            super.draw(ctx);
            return;
        }

        var far = localToGlobal(new h2d.col.Point(viewWidth, viewHeight));
        ctx.clipRenderZone(absX, absY, far.x - absX, far.y - absY);
        // The same shift heaps makes for scrollX, down the other axis.
        absX -= scrollY * matB;
        absY -= scrollY * matD;
        super.draw(ctx);
        absX += scrollY * matB;
        absY += scrollY * matD;
        ctx.popRenderZone();
    }
}

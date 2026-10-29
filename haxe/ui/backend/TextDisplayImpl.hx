package haxe.ui.backend;

import h2d.Font;
import haxe.ui.Toolkit;
import haxe.ui.backend.heaps.HtmlFaces;
import haxe.ui.backend.heaps.HtmlLabelText;
import haxe.ui.backend.heaps.SDFFonts;

class TextDisplayImpl extends TextBase {
    /**
        What draws the text: an h2d.Text, or - while the label shows `htmlText` - an HtmlLabelText
        in its place (see validateData). Not the same object for the life of the label, so read it
        here each time rather than keeping it.
    **/
    public var sprite:h2d.Text;

    // defaults
    public static var defaultFontSize:Int = 12;

    public var isDefaultFont:Bool = true;

    public function new() {
        super();
        sprite = createText();
        sprite.visible = false;
        Toolkit.callLater(function() { // lets avoid text apearing at 0,0 initially by showing it 1 frame later
            sprite.visible = true;
        });
    }

    private override function get_supportsHtml():Bool {
        return true;
    }

    private override function validateData() {
        if (supportsHtml && _text == null && _htmlText != null) {
            var html = htmlSprite();
            if (html == null) {
                html = new HtmlLabelText(hxd.res.DefaultFont.get());
                // the faces are built at the size the label's own font already is (resizeFont)
                html.deviceSize = Std.int(Math.max(1, Math.abs(sprite.font.size)));
                replaceSprite(html);
            }
            // h2d.HtmlText throws on markup that is not XML; normalize never returns any
            html.text = HtmlFaces.normalize(normalizeText(_htmlText));
            return;
        }

        // A text input never gets here with an HtmlLabelText (its supportsHtml is false), so this
        // never replaces its h2d.TextInput.
        if (htmlSprite() != null) {
            var plain = new h2d.Text(hxd.res.DefaultFont.get());
            plain.lineBreak = false;
            replaceSprite(plain);
        }
        if (_text != null) {
            sprite.text = normalizeText(_text);
        } else if (_htmlText != null) {
            sprite.text = normalizeText(_htmlText);
        }
    }

    private inline function htmlSprite():HtmlLabelText {
        return Std.downcast(sprite, HtmlLabelText);
    }

    /**
        Puts `next` where `sprite` is - the same place among its parent's children, so it is drawn
        in the same order - and hands it everything the style and layout have already set on the
        old one: those are only set again when they change, and they have not.
    **/
    private function replaceSprite(next:h2d.Text) {
        var old = sprite;
        next.smooth = old.smooth;
        next.font = old.font;
        next.scaleX = old.scaleX;
        next.scaleY = old.scaleY;
        next.textColor = old.textColor;
        next.textAlign = old.textAlign;
        next.lineBreak = old.lineBreak;
        next.maxWidth = old.maxWidth;
        next.x = old.x;
        next.y = old.y;
        next.alpha = old.alpha;
        next.visible = old.visible;

        var parent = old.parent;
        if (parent != null) {
            var index = parent.getChildIndex(old);
            old.remove();
            parent.addChildAt(next, index);
        }
        sprite = next;
    }

    // ---- links (`<a href>` in htmlText), in the parent component's units, as haxeui-cs has them ----

    /** How many links the htmlText holds. **/
    public function linkCount():Int {
        var html = htmlSprite();
        return (html == null) ? 0 : html.linkHrefs.length;
    }

    /** A link's href, by its place in the text (0 is the first), or null. **/
    public function linkHref(index:Int):Null<String> {
        var html = htmlSprite();
        if (html == null || index < 0 || index >= html.linkHrefs.length) {
            return null;
        }
        return html.linkHrefs[index];
    }

    /**
        The link at a point in the parent component's own units, or -1.

        The text's own numbers are device pixels from the sprite's origin (see measureText), so the
        point is moved to that origin and stood up by the sprite's scale before it is looked up.
    **/
    public function linkAt(x:Float, y:Float):Int {
        var html = htmlSprite();
        if (html == null || html.scaleX <= 0 || html.scaleY <= 0) {
            return -1;
        }
        return html.linkAt((x - html.x) / html.scaleX, (y - html.y) / html.scaleY);
    }
    
    private var _currentFontData:FontData = null;
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;

        var isBitmap = false;
        if (_fontInfo != null && _fontInfo.data != null) {
            if (_fontInfo.data != _currentFontData) {
                _currentFontData = _fontInfo.data;

                var font:Font = null;
                var sdfDetails = SDFFonts.get(_fontInfo.name);
                if (sdfDetails != null) {
                    font = _currentFontData.toSdfFont(defaultFontSize, sdfDetails.channel, sdfDetails.alphaCutoff, sdfDetails.smoothing).clone();
                } else {
                    font = _currentFontData.toFont().clone();
                    isBitmap = true;
                }

                if (sprite.font != font) {
                    sprite.font = font;
                    measureTextRequired = true;
                }

                isDefaultFont = false;
            }
        }

        if (_textStyle != null) {
            var fontSizeValue = Std.int(_textStyle.fontSize);
            if (fontSizeValue <= 0) {
                fontSizeValue = Std.int(defaultFontSize);
            }

            var currentFontSize = sprite.font.size;
            if (currentFontSize < 0) { // no Math.fabs
                currentFontSize = -currentFontSize;
            }

            // Glyphs are baked at the size they will be DRAWN at, not the size
            // they are laid out at. Toolkit.scaleX magnifies the whole
            // component tree (ScreenImpl sets it on every root), so a font
            // built for an 11 pixel em and blown up by 1.5 is an 11 pixel
            // rasterisation stretched over 16.5 pixels — soft edges, and glyph
            // advances that were whole numbers landing on thirds of a pixel.
            // Building it at 17 and standing the text down by 11/17 puts the
            // same words in the same place out of a rasterisation that matches
            // the screen. At scale 1 every line of this is an identity.
            var deviceSize = deviceFontSize(fontSizeValue);
            if (currentFontSize != deviceSize) {
                resizeFont(deviceSize, isBitmap);
                // Exactly, not 1/scale: the baked size is a whole number, and
                // this is what keeps a 15 point label 15 points wide after it
                // was rounded to 23 device pixels rather than 22.5.
                sprite.setScale(fontSizeValue / deviceSize);
                measureTextRequired = true;
            }

            if (_displayData.wordWrap != sprite.lineBreak) {
                sprite.lineBreak = _displayData.wordWrap;
                measureTextRequired = true;
            }

            var textAlign:h2d.Text.Align = getAlign(_textStyle.textAlign);
            if (sprite.textAlign != textAlign) {
                sprite.textAlign = textAlign;
                measureTextRequired = true;
            }

            if (sprite.textColor != _textStyle.color) {
                sprite.textColor = _textStyle.color;
            }
        }

        return measureTextRequired;
    }
    
    /**
        The size to BUILD a font at for text that will be laid out at
        `fontSizeValue`: the same size in device pixels, which is what
        Toolkit.scaleX means. Never below 1 — a component may be styled at a
        size of 0 before its real style arrives.
    **/
    private function deviceFontSize(fontSizeValue:Int):Int {
        var scale = Toolkit.scaleX;
        if (scale <= 0) {
            scale = 1;
        }
        var size = Math.round(fontSizeValue * scale);
        return (size < 1) ? 1 : size;
    }

    private function resizeFont(fontSizeValue:Int, isBitmap:Bool) {
        // HTML faces are built at deviceSize, and setting the font below rebuilds the text, which
        // loads them: it has to be the new size by then.
        var html = htmlSprite();
        if (html != null) {
            html.deviceSize = fontSizeValue;
        }
        var temp = sprite.font.clone();
        sprite.font = null;
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

    private override function validatePosition() {
        if (autoWidth == true && sprite.textAlign == h2d.Text.Align.Center) {
            sprite.x = (_left) + (_width / 2);
        } else {
            sprite.x = (_left);
        }

        var offset:Float = 0;
        if (!isDefaultFont) {
            var currentFontSize = sprite.font.size;
            if (currentFontSize < 0) { // no Math.fabs
                currentFontSize = -currentFontSize;
            }
            // The font's own numbers are in the text's units, which are device
            // pixels now; this offset is a position in the component, which is
            // laid out in layout units. sprite.scaleX is the ratio between them.
            offset = ((currentFontSize - sprite.font.baseLine) / 2) * sprite.scaleX;
        }

        sprite.y = (_top) + offset;
    }
    
    private override function validateDisplay() {
        if (autoWidth == false) {
            // maxWidth is where the words WRAP, measured in the text's own
            // units — device pixels — while the width it has to fit is laid out
            // in layout units.
            var wrapAt = _width != 0 ? _width : _textWidth;
            sprite.maxWidth = (sprite.scaleX > 0) ? wrapAt / sprite.scaleX : wrapAt;
        }else if (sprite.textAlign == h2d.Text.Align.Right){
            sprite.x =_width;
        }else if (sprite.textAlign == h2d.Text.Align.Center) {
            sprite.x = (_left) + (_width / 2);
        }
    }
    
    private var autoWidth(get, null):Bool;
    private function get_autoWidth():Bool {
        return parentComponent.autoWidth;
    }
    
    private override function measureText() {
        // What the text measures in the units the LAYOUT is in: the glyphs are
        // built at device size and the text stands scaled down to match, so its
        // own numbers are that much bigger than the component around it.
        _textWidth = sprite.textWidth * sprite.scaleX;
        _textHeight = sprite.textHeight * sprite.scaleY;

        _textWidth = Math.round(_textWidth);
        _textHeight = Math.round(_textHeight);
        
        if (_textWidth % 2 != 0) {
            _textWidth++;
        }
        if (_textHeight % 2 == 0) {
            _textHeight++;
        }
    }

    private function createText():h2d.Text {
        var text = new h2d.Text(hxd.res.DefaultFont.get(), parentComponent);
        text.lineBreak = false;
        return text;
    }

    private function getAlign(align:String):h2d.Text.Align {
        return switch(align) {
            case "left":    h2d.Text.Align.Left;
            case "right":   h2d.Text.Align.Right;
            case "center":  h2d.Text.Align.Center;
            case _:         h2d.Text.Align.Left;    //TODO  - justify
        }
    }
    
    private function normalizeText(text:String):String {
        if (text == null) {
            return "";
        }
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
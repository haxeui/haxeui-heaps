package haxe.ui.backend;

class TextDisplayImpl extends TextBase {
    public var sprite:h2d.Text;

    public function new() {
        super();
        sprite = createText();
    }

    private override function validateData() {
        sprite.text = _text;
    }
    
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;

        if (_textStyle != null) {
            var textAlign:h2d.Text.Align = getAlign(_textStyle.textAlign);
            if (sprite.textAlign != textAlign) {
                sprite.textAlign = textAlign;
            }

            var fontSizeValue = Std.int(_textStyle.fontSize);
            if ((_fontInfo != null && sprite.font.name != _fontInfo.data)
                || sprite.font.size != fontSizeValue) {
                var fontName:String = _fontInfo != null ? _fontInfo.data : sprite.font.name;
                //sprite.font = hxd.res.FontBuilder.getFont(FontDetect.getFontName(fontName), fontSizeValue > 0 ? fontSizeValue : Toolkit.pixelsPerRem);
                measureTextRequired = true;
            }

            if (sprite.textColor != _textStyle.color) {
                sprite.textColor = _textStyle.color;
            }
        }

        return measureTextRequired;
    }
    
    private override function validatePosition() {
        sprite.x = _left;
        sprite.y = _top;
    }
    
    private override function validateDisplay() {
        sprite.maxWidth = _width != 0 ? _width : _textWidth;
    }
    
    private override function measureText() {
        _textWidth = sprite.textWidth;
        _textHeight = sprite.textHeight;
    }

    private function createText():h2d.Text {
        return new h2d.Text(hxd.res.DefaultFont.get());
    }

    private function getAlign(align:String):h2d.Text.Align {
        return switch(align) {
            case "left":    h2d.Text.Align.Left;
            case "right":   h2d.Text.Align.Right;
            case "center":  h2d.Text.Align.Center;
            case _:         h2d.Text.Align.Left;    //TODO  - justify
        }
    }
}
package haxe.ui.backend;

class TextDisplayImpl extends TextBase {
    public var sprite:h2d.Text;

    // defaults
    public static var channel:h2d.Font.SDFChannel = 0;
    public static var alphaCutoff:Float = 0.5;
    public static var smoothing:Float = 1 / 2;
    
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

            if (_fontInfo != null && _fontInfo.data != null) {
                var fontSizeValue = Std.int(_textStyle.fontSize);
                if (fontSizeValue <= 0) {
                    fontSizeValue = Toolkit.pixelsPerRem;
                    fontSizeValue = _fontInfo.data.toFont().size;
                }
                var font = _fontInfo.data.toSdfFont(fontSizeValue, TextDisplayImpl.channel, TextDisplayImpl.alphaCutoff, TextDisplayImpl.smoothing);
                if (sprite.font != font) {
                    sprite.font = font;
                    measureTextRequired = true;
                }
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
        
        _textWidth = Math.round(_textWidth + 2);
        _textHeight = Math.round(_textHeight);
        
        if (_textWidth % 2 == 0) {
            _textWidth++;
        }
        if (_textHeight % 2 == 0) {
            _textHeight++;
        }
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
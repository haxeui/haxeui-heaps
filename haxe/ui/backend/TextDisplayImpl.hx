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
        sprite.text = normalizeText(_text);
    }
    
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;

        if (_textStyle != null) {
            var textAlign:h2d.Text.Align = getAlign(_textStyle.textAlign);
            if (sprite.textAlign != textAlign) {
                sprite.textAlign = textAlign;
                measureTextRequired = true;
            }

            if (_displayData.wordWrap != sprite.lineBreak) {
                sprite.lineBreak = _displayData.wordWrap;
                measureTextRequired = true;
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
        if (autoWidth == true && sprite.textAlign == h2d.Text.Align.Center) {
            sprite.x = _left + (_width / 2) - 1; // TODO: all a bit strange
        } else {
            sprite.x = _left;
        }
        sprite.y = _top;
    }
    
    private override function validateDisplay() {
        if (autoWidth == false) {
            sprite.maxWidth = _width != 0 ? _width : _textWidth;
        } else if (sprite.textAlign == h2d.Text.Align.Center) {
            sprite.x = _left + (_width / 2) - 1; // TODO: all a bit strange
        }
    }
    
    private var autoWidth(get, null):Bool;
    private function get_autoWidth():Bool {
        return parentComponent.autoWidth;
    }
    
    private override function measureText() {
        _textWidth = sprite.textWidth;
        _textHeight = sprite.textHeight;
        
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
        var text = new h2d.Text(hxd.res.DefaultFont.get());
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
            return text;
        }
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
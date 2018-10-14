package haxe.ui.backend;

import haxe.ui.assets.FontInfo;
import haxe.ui.backend.heaps.util.FontDetect;
import haxe.ui.core.Component;
import haxe.ui.core.TextDisplay.TextDisplayData;
import haxe.ui.styles.Style;

class TextDisplayBase {
    private var _displayData:TextDisplayData = new TextDisplayData();

    public var sprite:h2d.Text;

    public var parentComponent:Component;
    
    private var _text:String;
    private var _textStyle:Style;
    
    private var _left:Float = 0;
    private var _top:Float = 0;
    private var _width:Float = 0;
    private var _height:Float = 0;
    private var _textWidth:Float = 0;
    private var _textHeight:Float = 0;
    
    private var _fontInfo:FontInfo;
    
    public function new() {
        sprite = createText();
    }

    private function validateData() {
        sprite.text = _text;
    }
    
    private function validateStyle():Bool {
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
                sprite.font = hxd.res.FontBuilder.getFont(FontDetect.getFontName(fontName), fontSizeValue > 0 ? fontSizeValue : Toolkit.pixelsPerRem);
                measureTextRequired = true;
            }

            if (sprite.textColor != _textStyle.color) {
                sprite.textColor = _textStyle.color;
            }

            //TODO - wordWrap - multiline
        }

        return measureTextRequired;
    }
    
    private function validatePosition() {
        sprite.x = _left;
        sprite.y = _top;
    }
    
    private function validateDisplay() {
        sprite.maxWidth = _width;
    }
    
    private function measureText() {
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

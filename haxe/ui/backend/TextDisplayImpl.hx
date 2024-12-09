package haxe.ui.backend;

import h2d.Font;
import haxe.ui.Toolkit;
import haxe.ui.backend.heaps.SDFFonts;

class TextDisplayImpl extends TextBase {
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

    private override function validateData() {
        if (_text != null) {
            sprite.text = normalizeText(_text);
        } else if (_htmlText != null) {
            sprite.text = normalizeText(_htmlText);
        }
        
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

            if (currentFontSize != fontSizeValue) {
                resizeFont(fontSizeValue, isBitmap);
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
    
    private function resizeFont(fontSizeValue:Int, isBitmap:Bool) {
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
            offset = ((currentFontSize - sprite.font.baseLine) / 2);
        }

        sprite.y = (_top) + offset;
    }
    
    private override function validateDisplay() {
        if (autoWidth == false) {
            sprite.maxWidth = _width != 0 ? _width : _textWidth;
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
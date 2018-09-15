package haxe.ui.backend.heaps;

import h2d.Tile;
import haxe.ui.styles.Style;
import haxe.ui.util.ColorUtil;
import haxe.ui.util.filters.Blur;
import haxe.ui.util.filters.DropShadow;
import haxe.ui.util.filters.Filter;
import haxe.ui.util.Rectangle;

class StyleHelper
{
    private static var GRADIENT_SEGMENTS:Int = 10;
    private static var GRADIENT_CACHE:Map<String, Tile> = new Map<String, Tile>();
    private static var RECTANGLE_HELPER:Rectangle = new Rectangle();

    public static function apply(s:UISprite, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        if (w <= 0 || h <= 0) {
            return;
        }

        RECTANGLE_HELPER.left = 0;
        RECTANGLE_HELPER.top = 0;
        RECTANGLE_HELPER.width = w;
        RECTANGLE_HELPER.height = h;

        var borderRadius:Float = 0;
        if (style.borderRadius != null) {
            borderRadius = style.borderRadius;
        }

        if (style.opacity != null) {
            s.alpha = style.opacity;
        }

        var borderRadius:Float = 0;
        if (style.borderRadius != null) {
            borderRadius = style.borderRadius;
        }

        var borderOpacity:Float = style.borderOpacity != null ? style.borderOpacity : 1;
        if (style.borderLeftSize != null && style.borderLeftSize != 0
            && style.borderLeftSize == style.borderRightSize
            && style.borderLeftSize == style.borderBottomSize
            && style.borderLeftSize == style.borderTopSize

            && style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor) { // full border

            var borderSize:Int = Std.int(style.borderLeftSize);
            RECTANGLE_HELPER.left += borderSize;// / 2;
            RECTANGLE_HELPER.top += borderSize;// / 2;
            RECTANGLE_HELPER.width -= borderSize * 2;// / 2;
            RECTANGLE_HELPER.height -= borderSize * 2;// / 2;
            s.lineStyle(borderSize, style.borderLeftColor, borderOpacity);
            s.drawRect(0, 0, w, h-1);
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                s.lineStyle(style.borderTopSize, style.borderTopColor, borderOpacity);
                s.moveTo(0, 0);
                s.lineTo(w, 0);
                RECTANGLE_HELPER.top += style.borderTopSize;
                RECTANGLE_HELPER.height -= style.borderTopSize;
            }

            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                s.lineStyle(style.borderBottomSize, style.borderBottomColor, borderOpacity);
                s.moveTo(0, h - style.borderBottomSize);
                s.lineTo(w, h - style.borderBottomSize);
                RECTANGLE_HELPER.height -= style.borderBottomSize;
            }

            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                s.lineStyle(style.borderLeftSize, style.borderLeftColor, borderOpacity);
                s.moveTo(0, 0);
                s.lineTo(0, h);
                RECTANGLE_HELPER.left += style.borderLeftSize;
                RECTANGLE_HELPER.width -= style.borderLeftSize;
            }

            if (style.borderRightSize != null && style.borderRightSize > 0) {
                s.lineStyle(style.borderRightSize, style.borderRightColor, borderOpacity);
                s.moveTo(w - style.borderRightSize + 1, 0);
                s.lineTo(w - style.borderRightSize + 1, h);
                RECTANGLE_HELPER.width -= style.borderRightSize;
            }
        }

        var backgroundOpacity:Int = (style.backgroundOpacity != null ? Std.int(style.backgroundOpacity*255) : 255) << 24;
        if (style.backgroundColor != null) {
            s.lineStyle();
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }

                var gradientID:String = '${style.backgroundColor}_${style.backgroundColorEnd}_$gradientType';
                var tile:Tile;
                var scaleXTile:Float = w;
                var scaleYTile:Float = h;
                if((tile = GRADIENT_CACHE.get(gradientID)) == null || tile.isDisposed())
                {
                    var arr:Array<Int> = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, GRADIENT_SEGMENTS);
                    var bmp:hxd.BitmapData = null;
                    if (gradientType == "vertical") {
                        bmp = new hxd.BitmapData(1, GRADIENT_SEGMENTS);
                        for (i in 0...arr.length) {
                            bmp.setPixel(0, i, backgroundOpacity | arr[i]);
                        }
                        scaleYTile /= GRADIENT_SEGMENTS;
                    } else if (gradientType == "horizontal") {
                        bmp = new hxd.BitmapData(GRADIENT_SEGMENTS, 1);
                        for (i in 0...arr.length) {
                            bmp.setPixel(i, 0, backgroundOpacity | arr[i]);
                        }
                        scaleXTile /= GRADIENT_SEGMENTS;
                    }

                    tile = h2d.Tile.fromBitmap(bmp);
                    bmp.dispose();

                    GRADIENT_CACHE.set(gradientID, tile);
                }
                else
                {
                    if (gradientType == "vertical") {
                        scaleYTile /= GRADIENT_SEGMENTS;
                    } else if (gradientType == "horizontal") {
                        scaleXTile /= GRADIENT_SEGMENTS;
                    }
                }

                s.smooth = true;
                s.beginTileFill(0, 0, scaleXTile, scaleYTile, tile);
            } else {
                s.smooth = false;
                s.beginFill(style.backgroundColor, backgroundOpacity);
            }

            s.drawRect(RECTANGLE_HELPER.left, RECTANGLE_HELPER.top, RECTANGLE_HELPER.width, RECTANGLE_HELPER.height);
            s.endFill();
        }


        if (style.filter != null && style.filter.length > 0) {
            var filter:Filter = style.filter[0];
            var nativeFilter:h2d.filter.Filter = null;
            if (!_filterEqualTo(filter, nativeFilter)) {
                switch (Type.getClass(filter)) {
                    case DropShadow:
                        var ds:DropShadow = cast(filter, DropShadow);
                        if (ds.inner) {
                            //TODO
                            //nativeFilter = new h2d.filter.DropShadow(ds.distance, ds.angle, ds.color, ds.alpha, (ds.blurX + ds.blurY) * 0.5, Std.int(ds.strength), ds.quality);
                        } else {
                            nativeFilter = new h2d.filter.DropShadow(ds.distance, ds.angle, ds.color, ds.alpha, (ds.blurX + ds.blurY) * 0.5, Std.int(ds.strength), ds.quality);
                        }
                    case Blur:
                        var b:Blur = cast(filter, Blur);
                        nativeFilter = new h2d.filter.Blur(b.amount);
                }

                s.filter = nativeFilter;
            }
        } else if (s.filter != null) {
            s.filter = null;
        }
    }

    private static inline function _filterEqualTo(hxf:Filter, nativeFilter:h2d.filter.Filter):Bool {
        if ((hxf != null && nativeFilter == null) || (hxf == null && nativeFilter != null)) {
            return false;
        }

        if (hxf == null && nativeFilter == null) {
            return true;
        }

        return switch (Type.getClass(hxf)) {
            case DropShadow:
                var ds:DropShadow = cast(hxf, DropShadow);
                if (!Std.is(nativeFilter, h2d.filter.DropShadow)) {
                    false;
                } else {
                    var nds:h2d.filter.DropShadow = cast(nativeFilter, h2d.filter.DropShadow);
                    !(ds.distance != nds.distance ||
                    ds.angle != nds.angle ||
                    ds.color != nds.color ||
                    ds.alpha != nds.alpha ||
                    ds.quality != nds.quality ||
                     Std.int(ds.strength) != nds.gain ||
                     (ds.blurX + ds.blurY) * 0.5 != nds.radius);
                }
            case Blur:
                var b:Blur = cast(hxf, Blur);
                var nb:h2d.filter.Blur = cast(nativeFilter, h2d.filter.Blur);
                (b.amount != nb.radius);
            default:
                false;
        }
    }
}
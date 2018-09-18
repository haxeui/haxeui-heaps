package haxe.ui.backend.heaps;

import h2d.Tile;
import haxe.ui.assets.ImageInfo;
import haxe.ui.backend.heaps.BackgroundTile;
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

    private static var ID_BACKGROUND_COLOR:String = "backgroundColor";
    private static var ID_BACKGROUND_IMAGE:String = "backgroundImage";
    private static var ID_BACKGROUND_IMAGE_SLICE:String = "backgroundImageSlice";

    public static function apply(s:UISprite, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        if (w <= 0 || h <= 0) {
            return;
        }

        RECTANGLE_HELPER.left = 0;
        RECTANGLE_HELPER.top = 0;
        RECTANGLE_HELPER.width = w;
        RECTANGLE_HELPER.height = h;

        if (style.opacity != null) {
            s.alpha = style.opacity;
        }

        var borderRadius:Float = style.borderRadius != null ? style.borderRadius : 0;
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
            var halfBorderSize:Float = borderSize / 2;
            s.lineStyle(borderSize, style.borderLeftColor, borderOpacity);
            s.drawRect(halfBorderSize, halfBorderSize, w - borderSize, h - borderSize);
            RECTANGLE_HELPER.left += borderSize;
            RECTANGLE_HELPER.top += borderSize;
            RECTANGLE_HELPER.width -= borderSize * 2;
            RECTANGLE_HELPER.height -= borderSize * 2;
        } else { // compound border
            var heightTmp:Float = RECTANGLE_HELPER.height;
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                var halfBorderSize:Float = style.borderTopSize / 2;
                s.lineStyle(style.borderTopSize, style.borderTopColor, borderOpacity);
                s.moveTo(0, halfBorderSize);
                s.lineTo(w, halfBorderSize);
                RECTANGLE_HELPER.top += halfBorderSize;
                RECTANGLE_HELPER.height -= style.borderTopSize;
            }

            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                var halfBorderSize:Float = style.borderBottomSize / 2;
                var borderHeight:Float = h - halfBorderSize;
                s.lineStyle(style.borderBottomSize, style.borderBottomColor, borderOpacity);
                s.moveTo(0, borderHeight);
                s.lineTo(w, borderHeight);
                RECTANGLE_HELPER.top += halfBorderSize;
                RECTANGLE_HELPER.height -= style.borderBottomSize;
            }

            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                var halfBorderSize:Float = style.borderLeftSize / 2;
                s.lineStyle(style.borderLeftSize, style.borderLeftColor, borderOpacity);
                s.moveTo(halfBorderSize, 0);
                s.lineTo(halfBorderSize, h);
                RECTANGLE_HELPER.left += halfBorderSize;
                RECTANGLE_HELPER.width -= style.borderLeftSize;
            }

            if (style.borderRightSize != null && style.borderRightSize > 0) {
                var halfBorderSize:Float = style.borderRightSize / 2;
                var borderWidth:Float = w - halfBorderSize;
                s.lineStyle(style.borderRightSize, style.borderRightColor, borderOpacity);
                s.moveTo(borderWidth, 0);
                s.lineTo(borderWidth, h);
                RECTANGLE_HELPER.left += halfBorderSize;
                RECTANGLE_HELPER.width -= style.borderRightSize;
            }
        }

        if (style.backgroundImage != null) {
            Toolkit.assets.getImage(style.backgroundImage, function(imageInfo:ImageInfo) {
                var tile:Tile = Tile.fromBitmap(imageInfo.data);
                if (style.backgroundImageClipTop != null
                    && style.backgroundImageClipLeft != null
                    && style.backgroundImageClipBottom != null
                    && style.backgroundImageClipRight != null) {

                    tile = tile.sub(style.backgroundImageClipLeft,
                        style.backgroundImageClipTop,
                        style.backgroundImageClipRight - style.backgroundImageClipLeft,
                        style.backgroundImageClipBottom - style.backgroundImageClipTop);
                }

                if (style.backgroundImageSliceTop != null
                    && style.backgroundImageSliceLeft != null
                    && style.backgroundImageSliceBottom != null
                    && style.backgroundImageSliceRight != null) {

                    var slice:Rectangle = new Rectangle(style.backgroundImageSliceLeft,
                        style.backgroundImageSliceTop,
                        style.backgroundImageSliceRight - style.backgroundImageSliceLeft,
                        style.backgroundImageSliceBottom - style.backgroundImageSliceTop);

                    s.removeBackground(ID_BACKGROUND_IMAGE);
                    var background:BackgroundTileGroup = cast s.getBackground(ID_BACKGROUND_IMAGE_SLICE);
                    if (background == null) {
                        background = new BackgroundTileGroup(tile, slice,
                            Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                            Std.int(RECTANGLE_HELPER.width), Std.int(RECTANGLE_HELPER.height));
                        s.addBackground(ID_BACKGROUND_IMAGE_SLICE, background);
                    } else {
                        background.set(tile, slice,
                            Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                            Std.int(RECTANGLE_HELPER.width), Std.int(RECTANGLE_HELPER.height));
                    }

                    RECTANGLE_HELPER.left += style.backgroundImageSliceLeft;
                    RECTANGLE_HELPER.top += style.backgroundImageSliceTop;
                    RECTANGLE_HELPER.width -= tile.width - style.backgroundImageSliceRight + style.backgroundImageSliceLeft;
                    RECTANGLE_HELPER.height -= tile.height - style.backgroundImageSliceBottom + style.backgroundImageSliceTop;
                } else {
                    var width:Int = tile.width;
                    var height:Int = tile.height;
                    var repeat:Bool = style.backgroundImageRepeat == "repeat";
                    switch(style.backgroundImageRepeat) {
                        case "repeat", "stretch":
                            width = Std.int(RECTANGLE_HELPER.width);
                            height = Std.int(RECTANGLE_HELPER.height);

                        default:

                    }

                    s.smooth = style.backgroundImageRepeat == "stretch";

                    s.removeBackground(ID_BACKGROUND_IMAGE_SLICE);
                    var background:BackgroundTile = cast s.getBackground(ID_BACKGROUND_IMAGE);
                    if (background == null) {
                        background = new BackgroundTile(tile,
                            Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                            width, height, repeat);
                        s.addBackground(ID_BACKGROUND_IMAGE, background);
                    } else {
                        background.set(tile,
                            Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                            width, height);
                        background.repeat = repeat;
                    }
                }
            });
        } else {
            s.removeBackground(ID_BACKGROUND_IMAGE_SLICE);
            s.removeBackground(ID_BACKGROUND_IMAGE);
        }

        var backgroundOpacity:Float = style.backgroundOpacity != null ? style.backgroundOpacity : 1;
        if (style.backgroundColor != null) {
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }

                var gradientID:String = '${style.backgroundColor}_${style.backgroundColorEnd}_$gradientType';
                var tile:Tile = GRADIENT_CACHE.get(gradientID);
                if(tile == null || tile.isDisposed())
                {
                    var opacity:Int = Std.int(backgroundOpacity * 255) << 24;
                    var arr:Array<Int> = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, GRADIENT_SEGMENTS);
                    var bmp:hxd.BitmapData = null;
                    if (gradientType == "vertical") {
                        bmp = new hxd.BitmapData(1, GRADIENT_SEGMENTS);
                        for (i in 0...arr.length) {
                            bmp.setPixel(0, i, opacity | arr[i]);
                        }
                    } else if (gradientType == "horizontal") {
                        bmp = new hxd.BitmapData(GRADIENT_SEGMENTS, 1);
                        for (i in 0...arr.length) {
                            bmp.setPixel(i, 0, opacity | arr[i]);
                        }
                    }

                    tile = h2d.Tile.fromBitmap(bmp);
                    bmp.dispose();

                    GRADIENT_CACHE.set(gradientID, tile);
                }

                s.smooth = true;

                var background:BackgroundTile = cast s.getBackground(ID_BACKGROUND_COLOR);
                if (background == null) {
                    background = new BackgroundTile(tile,
                        Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                        Std.int(RECTANGLE_HELPER.width), Std.int(RECTANGLE_HELPER.height));
                    s.addBackground(ID_BACKGROUND_COLOR, background);
                } else {
                    background.set(tile,
                        Std.int(RECTANGLE_HELPER.left), Std.int(RECTANGLE_HELPER.top),
                        Std.int(RECTANGLE_HELPER.width), Std.int(RECTANGLE_HELPER.height));
                }
            } else {
                s.smooth = false;

                s.lineStyle();
                s.beginFill(style.backgroundColor, backgroundOpacity);
                s.drawRect(RECTANGLE_HELPER.left, RECTANGLE_HELPER.top, RECTANGLE_HELPER.width, RECTANGLE_HELPER.height);
                s.endFill();
            }
        } else {
            s.removeBackground(ID_BACKGROUND_COLOR);
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
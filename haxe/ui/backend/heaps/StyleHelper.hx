package haxe.ui.backend.heaps;

import haxe.ui.assets.ImageInfo;
import haxe.ui.backend.heaps.shader.StyleShader;
import haxe.ui.styles.Style;
import haxe.ui.util.filters.Blur;
import haxe.ui.util.filters.DropShadow;
import haxe.ui.util.filters.Filter;
import haxe.ui.util.Rectangle;

class StyleHelper
{
    private static var RECTANGLE_HELPER:Rectangle = new Rectangle();

    public static function apply(s:UISprite, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        if (w <= 0 || h <= 0) {
            return;
        }

        if (style.opacity != null) {
            s.alpha = style.opacity;
        }

        var borderOpacity:Int = Std.int((style.borderOpacity != null ? style.borderOpacity : 1) * 255);
        var backgroundOpacity:Int = Std.int((style.backgroundOpacity != null ? style.backgroundOpacity : 1) * 255);

        var hasFullBorder:Bool = borderOpacity > 0
            && style.borderLeftSize != null && style.borderLeftSize != 0
            && style.borderLeftSize == style.borderRightSize
            && style.borderLeftSize == style.borderBottomSize
            && style.borderLeftSize == style.borderTopSize
            && style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor;
        var hasPartialBorder:Bool = !hasFullBorder
            && ((style.borderTopSize != null && style.borderTopSize > 0)
                || (style.borderBottomSize != null && style.borderBottomSize > 0)
                || (style.borderLeftSize != null && style.borderLeftSize > 0)
                || (style.borderRightSize != null && style.borderRightSize > 0));
        var hasBackgroundImage:Bool = backgroundOpacity > 0 && style.backgroundImage != null;
        var hasBackgroundGradient:Bool = !hasBackgroundImage && backgroundOpacity > 0 && style.backgroundColor != null && style.backgroundColorEnd != null;
        var hasFlatBackground:Bool = !hasBackgroundImage && backgroundOpacity > 0 && style.backgroundColor != null;

        var styleShader:StyleShader = s.getShader(StyleShader);
        if (hasFlatBackground || hasBackgroundGradient || hasBackgroundImage || hasFullBorder) {
            if (styleShader == null) {
                styleShader = s.addShader(new StyleShader());
            }

            backgroundOpacity = backgroundOpacity << 24;
            borderOpacity = borderOpacity << 24;

            var hasRadius:Bool = style.borderRadius != null && !hasPartialBorder;

            styleShader.size.set(w, h);
            styleShader.hasRadius = hasRadius;
            styleShader.hasBackgroundGradient = hasBackgroundGradient;
            styleShader.hasFullBorder = hasFullBorder;

            if (hasBackgroundImage) {
                Toolkit.assets.getImage(style.backgroundImage, function(imageInfo:ImageInfo) {
                    var tex = h3d.mat.Texture.fromBitmap(imageInfo.data);
                    var tile = h2d.Tile.fromBitmap(imageInfo.data);
                    var backgroundOffsetU:Float = 0;
                    var backgroundOffsetV:Float = 0;
                    var backgroundScaleU:Float = 1.0;
                    var backgroundScaleV:Float = 1.0;
                    var imageWidth:Int = imageInfo.width;
                    var imageHeight:Int = imageInfo.height;
                    var hasClip:Bool = style.backgroundImageClipTop != null
                        && style.backgroundImageClipLeft != null
                        && style.backgroundImageClipBottom != null
                        && style.backgroundImageClipRight != null;
                    var hasSlice:Bool = style.backgroundImageSliceTop != null
                        && style.backgroundImageSliceLeft != null
                        && style.backgroundImageSliceBottom != null
                        && style.backgroundImageSliceRight != null;

                    tex.filter = style.backgroundImageRepeat == "stretch" ? Linear : Nearest;
                    tex.wrap = style.backgroundImageRepeat == "repeat" ? Repeat : Clamp;

                    styleShader.backgroundImage = tex;
                    styleShader.hasBackgroundImage = hasBackgroundImage;
                    styleShader.hasBackgroundImageSlice = hasSlice;

                    if (hasClip) {
                        imageWidth = Std.int(style.backgroundImageClipRight - style.backgroundImageClipLeft);
                        imageHeight = Std.int(style.backgroundImageClipBottom - style.backgroundImageClipTop);

                        backgroundOffsetU = style.backgroundImageClipLeft / imageWidth;
                        backgroundOffsetV = style.backgroundImageClipTop / imageHeight;
                        backgroundScaleU = imageWidth / imageInfo.width;
                        backgroundScaleV = imageHeight / imageInfo.height;
                    }

                    if (hasSlice) {
                        styleShader.backgroundImageSliceBox.set(
                            style.backgroundImageSliceLeft / w,
                            style.backgroundImageSliceTop / h,
                            1 - (imageWidth - style.backgroundImageSliceRight) / w,
                            1 - (imageHeight - style.backgroundImageSliceBottom) / h);

                        styleShader.backgroundImageSliceTexture.set(
                            style.backgroundImageSliceLeft / imageWidth,
                            style.backgroundImageSliceTop / imageHeight,
                            1 - (imageWidth - style.backgroundImageSliceRight) / imageWidth,
                            1 - (imageHeight - style.backgroundImageSliceBottom) / imageHeight
                        );
                    } else if (style.backgroundImageRepeat != "stretch" && !hasClip) {
                            backgroundScaleU = w / imageInfo.width;
                            backgroundScaleV = h / imageInfo.height;
                    }

                    styleShader.backgroundImageUV.set(backgroundOffsetU, backgroundOffsetV, backgroundScaleU, backgroundScaleV);
                });
            } else {
                if (hasFlatBackground) {
                    styleShader.backgroundColor.setColor(backgroundOpacity | style.backgroundColor);
                }

                if (hasBackgroundGradient) {
                    styleShader.backgroundColorEnd.setColor(backgroundOpacity | style.backgroundColorEnd);
                    if (style.backgroundGradientStyle == "vertical")
                        styleShader.backgroundDirection.set(0.0, 1.0);
                    else
                        styleShader.backgroundDirection.set(1.0, 0.0);
                }
            }

            if (hasFullBorder) {
                styleShader.borderColor.setColor(borderOpacity | style.borderLeftColor);
                styleShader.borderThickness = style.borderLeftSize;
            } else if (hasPartialBorder){
                if (style.borderTopSize != null && style.borderTopSize > 0) {
                    styleShader.hasBorderTop = true;
                    styleShader.borderColorTop.setColor(borderOpacity | style.borderTopColor);
                    styleShader.borderThicknessTop = style.borderTopSize;
                } else {
                    styleShader.hasBorderTop = false;
                }

                if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                    styleShader.hasBorderBottom = true;
                    styleShader.borderColorBottom.setColor(borderOpacity | style.borderBottomColor);
                    styleShader.borderThicknessBottom = style.borderBottomSize;
                } else {
                    styleShader.hasBorderBottom = false;
                }

                if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                    styleShader.hasBorderLeft = true;
                    styleShader.borderColorLeft.setColor(borderOpacity | style.borderLeftColor);
                    styleShader.borderThicknessLeft = style.borderLeftSize;
                } else {
                    styleShader.hasBorderLeft = false;
                }

                if (style.borderRightSize != null && style.borderRightSize > 0) {
                    styleShader.hasBorderRight = true;
                    styleShader.borderColorRight.setColor(borderOpacity | style.borderRightColor);
                    styleShader.borderThicknessRight = style.borderRightSize;
                } else {
                    styleShader.hasBorderRight = false;
                }
            }

            if (hasRadius) {
                styleShader.radius = style.borderRadius;
                styleShader.halfSize.set(w * 0.5, h * 0.5);
            }

            trace(s.getDebugShaderCode(false));
        } else if(styleShader != null) {
            s.removeShader(styleShader);
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
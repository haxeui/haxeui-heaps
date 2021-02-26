package haxe.ui.backend.heaps;

import h2d.Graphics;
import h2d.Tile;
import haxe.ui.assets.ImageInfo;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import haxe.ui.styles.Style;
import haxe.ui.util.ColorUtil;

class StyleHelper {
    public static function apply(c:ComponentImpl, style:Style, w:Float, h:Float):Void {
        if (w <= 0 || h <= 0) {
            return;
        }

        var container = c.getChildAt(0); // first child is always the style-objects container
        
        w *= Toolkit.scaleX;
        h *= Toolkit.scaleY;
        var borderSize:Rectangle = new Rectangle();
        var backgroundAlpha:Float = 1;
        if (style.backgroundOpacity != null) {
            backgroundAlpha = style.backgroundOpacity;
        }
        var borderAlpha:Float = 1;
        if (style.borderOpacity != null) {
            borderAlpha = style.borderOpacity;
        }
        
        var styleGraphics:Graphics = null;
        if (container.numChildren == 0) {
            styleGraphics = new Graphics();
            container.addChildAt(styleGraphics, 0);
        } else {
            styleGraphics = cast(container.getChildAt(0), Graphics);
        }
        styleGraphics.clear();
        
        if (style.backgroundColor != null) {
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }
                var arr:Array<Int> = null;
                var n:Int = 0;
                if (gradientType == "vertical") {
                    arr = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, Std.int(h));
                    var y = 0;
                    var offset = -1;
                    if (style.borderLeftSize > 0 || style.borderRightSize > 0) {
                        offset = 0;
                    }
                    for (col in arr) {
                        styleGraphics.lineStyle(1, col, backgroundAlpha);
                        styleGraphics.moveTo(offset, y);
                        styleGraphics.lineTo(w, y);
                        y++;
                    }
                } else if (gradientType == "horizontal") {
                    arr = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, Std.int(w + 1));
                    var x = 0;
                    for (col in arr) {
                        styleGraphics.lineStyle(1, col, backgroundAlpha);
                        styleGraphics.moveTo(x, 0);
                        styleGraphics.lineTo(x, h);
                        x++;
                    }
                }
            } else {
                styleGraphics.beginFill(style.backgroundColor, backgroundAlpha);
                styleGraphics.drawRect(0, 0, w, h);
                styleGraphics.endFill();
            }
        }

        if (style.backgroundImage != null) {
            Toolkit.assets.getImage(style.backgroundImage, function(imageInfo:ImageInfo) {
                var bgImageGraphics:Graphics = null;
                if (container.numChildren == 1) {
                    bgImageGraphics = new Graphics();
                    container.addChildAt(bgImageGraphics, 1);
                } else {
                    bgImageGraphics = cast(container.getChildAt(1), Graphics);
                }
                bgImageGraphics.clear();
                
                var tile = TileCache.get(style.backgroundImage);
                if (tile == null) {
                    tile = TileCache.set(style.backgroundImage, h2d.Tile.fromBitmap(imageInfo.data));
                }
                
                var trc:Rectangle = new Rectangle(0, 0, imageInfo.width, imageInfo.height);
                if (style.backgroundImageClipTop != null
                    && style.backgroundImageClipLeft != null
                    && style.backgroundImageClipBottom != null
                    && style.backgroundImageClipRight != null) {
                        trc = new Rectangle(style.backgroundImageClipLeft,
                                            style.backgroundImageClipTop,
                                            style.backgroundImageClipRight - style.backgroundImageClipLeft,
                                            style.backgroundImageClipBottom - style.backgroundImageClipTop);
                }
                
                var slice:Rectangle = null;
                if (style.backgroundImageSliceTop != null
                    && style.backgroundImageSliceLeft != null
                    && style.backgroundImageSliceBottom != null
                    && style.backgroundImageSliceRight != null) {
                    slice = new Rectangle(style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceTop,
                                          style.backgroundImageSliceRight - style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceBottom - style.backgroundImageSliceTop);
                }
                
                if (trc != null) {
                    tile = tile.sub(trc.left, trc.top, trc.width, trc.height);
                }
                if (slice != null) {
                    var rects:Slice9Rects = Slice9.buildRects(w, h, trc.width, trc.height, slice);
                    var srcRects:Array<Rectangle> = rects.src;
                    var dstRects:Array<Rectangle> = rects.dst;
                    
                    paintTile(bgImageGraphics, tile, srcRects[0], dstRects[0]);
                    paintTile(bgImageGraphics, tile, srcRects[1], dstRects[1]);
                    paintTile(bgImageGraphics, tile, srcRects[2], dstRects[2]);
                    
                    srcRects[3].bottom--;
                    paintTile(bgImageGraphics, tile, srcRects[3], dstRects[3]);

                    srcRects[4].bottom--;
                    paintTile(bgImageGraphics, tile, srcRects[4], dstRects[4]);
                    
                    srcRects[5].bottom--;
                    paintTile(bgImageGraphics, tile, srcRects[5], dstRects[5]);
                    
                    dstRects[6].bottom++;
                    paintTile(bgImageGraphics, tile, srcRects[6], dstRects[6]);
                    dstRects[7].bottom++;
                    paintTile(bgImageGraphics, tile, srcRects[7], dstRects[7]);
                    dstRects[8].bottom++;
                    paintTile(bgImageGraphics, tile, srcRects[8], dstRects[8]);
                } else {
                    paintTile(bgImageGraphics, tile, trc, new Rectangle(0, 0, w, h));
                }
            });
        }
        
        
        borderSize.left = style.borderLeftSize;
        borderSize.top = style.borderTopSize;
        borderSize.right = style.borderRightSize;
        borderSize.bottom = style.borderBottomSize;
        if (style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor
            
            && style.borderLeftSize != null
            && style.borderLeftSize == style.borderRightSize
            && style.borderLeftSize == style.borderBottomSize
            && style.borderLeftSize == style.borderTopSize
            ) { // full border
            
            styleGraphics.lineStyle(borderSize.left, style.borderLeftColor, borderAlpha);
            styleGraphics.moveTo(0, 0);
            styleGraphics.lineTo(w, 0);
            styleGraphics.lineTo(w, h - 1);
            styleGraphics.lineTo(0, h - 1);
            styleGraphics.lineTo(0, 0);
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                styleGraphics.lineStyle(borderSize.top, style.borderTopColor, borderAlpha);
                styleGraphics.moveTo(0, 0);
                styleGraphics.lineTo(w, 0);
            }
            
            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                styleGraphics.lineStyle(borderSize.bottom, style.borderBottomColor, borderAlpha);
                styleGraphics.moveTo(0, h - 1);
                styleGraphics.lineTo(w, h - 1);
            }
            
            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                styleGraphics.lineStyle(borderSize.left, style.borderLeftColor, borderAlpha);
                styleGraphics.moveTo(0, 0);
                styleGraphics.lineTo(0, h);
            }
            
            if (style.borderRightSize != null && style.borderRightSize > 0) {
                styleGraphics.lineStyle(borderSize.right, style.borderRightColor, borderAlpha);
                styleGraphics.moveTo(w, 0);
                styleGraphics.lineTo(w, h);
            }
        }
        
    }
    
    private static function paintTile(g:Graphics, tile:Tile, src:Rectangle, dst:Rectangle) {
        var scaleX = dst.width / src.width;
        var scaleY = dst.height / src.height;
        var sub = tile.sub(src.left * scaleX, src.top * scaleY, src.width, src.height);
        g.beginTileFill(dst.left, dst.top, scaleX, scaleY, sub);
        g.drawRect(dst.left, dst.top, dst.width, dst.height);
        g.endFill();
    }
}
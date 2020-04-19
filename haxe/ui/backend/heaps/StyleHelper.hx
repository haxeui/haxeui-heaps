package haxe.ui.backend.heaps;

import h2d.Tile;
import haxe.ui.assets.ImageInfo;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import haxe.ui.styles.Style;
import haxe.ui.util.ColorUtil;

class StyleHelper {
    public static function apply(c:ComponentImpl, style:Style, w:Float, h:Float):Void {
        c.clear();
        
        if (w <= 0 || h <= 0) {
            return;
        }

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
                    for (col in arr) {
                        c.lineStyle(1, col, backgroundAlpha);
                        c.moveTo(-1, y);
                        c.lineTo(w, y);
                        y++;
                    }
                } else if (gradientType == "horizontal") {
                    arr = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, Std.int(w + 1));
                    var x = 0;
                    for (col in arr) {
                        c.lineStyle(1, col, backgroundAlpha);
                        c.moveTo(x, 0);
                        c.lineTo(x, h);
                        x++;
                    }
                }
            } else {
                c.beginFill(style.backgroundColor, backgroundAlpha);
                c.drawRect(-1, 0, w + 1, h);
                c.endFill();
            }
        }

        if (style.backgroundImage != null) {
            Toolkit.assets.getImage(style.backgroundImage, function(imageInfo:ImageInfo) {
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
                    
                    paintTile(c, tile, srcRects[0], dstRects[0]);
                    paintTile(c, tile, srcRects[1], dstRects[1]);
                    paintTile(c, tile, srcRects[2], dstRects[2]);
                    
                    srcRects[3].bottom--;
                    paintTile(c, tile, srcRects[3], dstRects[3]);

                    srcRects[4].bottom--;
                    paintTile(c, tile, srcRects[4], dstRects[4]);
                    
                    srcRects[5].bottom--;
                    paintTile(c, tile, srcRects[5], dstRects[5]);
                    
                    dstRects[6].bottom++;
                    paintTile(c, tile, srcRects[6], dstRects[6]);
                    dstRects[7].bottom++;
                    paintTile(c, tile, srcRects[7], dstRects[7]);
                    dstRects[8].bottom++;
                    paintTile(c, tile, srcRects[8], dstRects[8]);
                } else {
                    
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
            
            c.lineStyle(borderSize.left, style.borderLeftColor, borderAlpha);
            c.moveTo(0, 0);
            c.lineTo(w, 0);
            c.lineTo(w, h - 1);
            c.lineTo(0, h - 1);
            c.lineTo(0, 0);
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                c.lineStyle(borderSize.top, style.borderTopColor, borderAlpha);
                c.moveTo(0, 0);
                c.lineTo(w, 0);
            }
            
            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                c.lineStyle(borderSize.bottom, style.borderBottomColor, borderAlpha);
                c.moveTo(0, h - 1);
                c.lineTo(w, h - 1);
            }
            
            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                c.lineStyle(borderSize.left, style.borderLeftColor, borderAlpha);
                c.moveTo(0, 0);
                c.lineTo(0, h + 2);
            }
            
            if (style.borderRightSize != null && style.borderRightSize > 0) {
                c.lineStyle(borderSize.right, style.borderRightColor, borderAlpha);
                c.moveTo(w, 0);
                c.lineTo(w, h);
            }
        }
        
    }
    
    private static function paintTile(c:ComponentImpl, tile:Tile, src:Rectangle, dst:Rectangle) {
        var scaleX = dst.width / src.width;
        var scaleY = dst.height / src.height;
        var sub = tile.sub(src.left * scaleX, src.top * scaleY, src.width, src.height);
        c.beginTileFill(dst.left, dst.top, scaleX, scaleY, sub);
        c.drawRect(dst.left, dst.top, dst.width, dst.height);
        c.endFill();
    }
}
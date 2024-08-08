package haxe.ui.backend.heaps;

import h2d.Graphics;
import h2d.Tile;
import haxe.ui.Toolkit;
import haxe.ui.assets.ImageInfo;
import haxe.ui.backend.heaps.TileCache;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import haxe.ui.styles.Style;
import hxd.clipper.Rect;


class StyleHelper {
    public static function apply(c:ComponentImpl, style:Style, w:Float, h:Float):Void {
        if (w <= 0 || h <= 0) {
            return;
        }

        var container = c.getChildAt(0); // first child is always the style-objects container
        if ( container == null ) {
            return; // fix crash resizing the window; container doesn't exist yet
        }

        var borderSize:Rectangle = new Rectangle();
        borderSize.left = style.borderLeftSize;
        borderSize.top = style.borderTopSize;
        borderSize.right = style.borderRightSize;
        borderSize.bottom = style.borderBottomSize;

        var borderColor:Rect = new Rect();
        borderColor.left = style.borderLeftColor;
        borderColor.top = style.borderTopColor;
        borderColor.right = style.borderRightColor;
        borderColor.bottom = style.borderBottomColor;

        var backgroundAlpha:Float = 1;
        if (style.backgroundOpacity != null) {
            backgroundAlpha = style.backgroundOpacity;
        }
        var borderAlpha:Float = 1;
        if (style.borderOpacity != null) {
            borderAlpha = style.borderOpacity;
        }
        
        var styleGraphics:Graphics = cast(container.getObjectByName("styleGraphics"), Graphics);
        if (styleGraphics == null) {
            styleGraphics = new Graphics();
            styleGraphics.name = "styleGraphics";
            container.addChildAt(styleGraphics, 0);
        }

        styleGraphics.clear();
        
        var borderRadius:Float = 0;
        var isCircle = (style.borderRadius == w && style.borderRadius == h);
        if (!isCircle && style.borderRadius != null && style.borderRadius > 0) {
            borderRadius = style.borderRadius + 1;
        }

        if (style.backgroundColor != null && backgroundAlpha > 0) {
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }
                
                var gradientSize = 256;
                if (borderRadius == 0) {
                    if (gradientType == "vertical" || gradientType == "horizontal") {
                        var width = w - borderSize.right - borderSize.left;
                        var height = h - borderSize.bottom - borderSize.top;
                        var tile = TileCache.getGradient(gradientType, style.backgroundColor, style.backgroundColorEnd, gradientSize, Std.int(backgroundAlpha * 255));
                        styleGraphics.beginTileFill(borderSize.left, borderSize.top, width / gradientSize, height / gradientSize, tile);
                        styleGraphics.drawRect(borderSize.left, borderSize.top, width, height);
                        styleGraphics.endFill();
                    }
                } else {
                    var width = w - borderSize.right - borderSize.left;
                    var height = h - borderSize.bottom - borderSize.top;
                    var tile = TileCache.getGradient(gradientType, style.backgroundColor, style.backgroundColorEnd, gradientSize, Std.int(backgroundAlpha * 255));
                    styleGraphics.beginTileFill(borderSize.left, borderSize.top, width / gradientSize, height / gradientSize, tile);
                    drawRoundedBackground(styleGraphics, w, h, borderSize, borderRadius);
                    styleGraphics.endFill();
                }
            } else {
                if (borderRadius == 0) {
                    styleGraphics.beginFill(style.backgroundColor, backgroundAlpha);
                    styleGraphics.drawRect(borderSize.left, borderSize.top, w - borderSize.right - borderSize.left, h - borderSize.bottom - borderSize.top);
                    styleGraphics.endFill();
                } else {
                    styleGraphics.beginFill(style.backgroundColor, backgroundAlpha);
                    drawRoundedBackground(styleGraphics, w, h, borderSize, borderRadius);
                    styleGraphics.endFill();
                }
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
                
                var tile = TileCache.get(style.backgroundImage);
                if (tile == null) {
                    tile = h2d.Tile.fromBitmap(imageInfo.data);
                    tile.getTexture().filter = Linear;
                    TileCache.set(style.backgroundImage, tile);
                }

                if (trc != null) {
                    /*
                    var subTile = TileCache.get(style.backgroundImage, trc);
                    if (subTile == null) {
                        subTile = tile.sub(trc.left, trc.top, trc.width, trc.height);
                        TileCache.set(style.backgroundImage, subTile, trc);
                    }
                    tile = subTile;
                    */
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
                
                if (slice != null) {
                    var rects:Slice9Rects = Slice9.buildRects(w, h, trc.width, trc.height, slice);
                    var srcRects:Array<Rectangle> = rects.src;
                    var dstRects:Array<Rectangle> = rects.dst;
                    
                    if (style.backgroundImageRepeat == "repeat") {
                        // The image is slightly scaled down to make sure there is no visible clip one the sides
                        var scaleX = dstRects[4].width / ( srcRects[4].width * Math.ceil(dstRects[4].width / srcRects[4].width) );
                        var scaleY = dstRects[4].height / ( srcRects[4].height * Math.ceil(dstRects[4].height / srcRects[4].height) );
                        
                        paintTile(bgImageGraphics, tile, srcRects[0], dstRects[0], style.backgroundImage);
                        paintTileRepeat(bgImageGraphics, tile, srcRects[1], scaleX, 1, dstRects[1], style.backgroundImage);
                        paintTile(bgImageGraphics, tile, srcRects[2], dstRects[2], style.backgroundImage);
                        
                        srcRects[3].bottom--;
                        paintTileRepeat(bgImageGraphics, tile, srcRects[3], 1, scaleY, dstRects[3], style.backgroundImage);
                        
                        srcRects[4].bottom--;
                        paintTileRepeat(bgImageGraphics, tile, srcRects[4], scaleX, scaleY, dstRects[4], style.backgroundImage);
                        
                        srcRects[5].bottom--;
                        paintTileRepeat(bgImageGraphics, tile, srcRects[5], 1, scaleY, dstRects[5], style.backgroundImage);
                        
                        dstRects[6].bottom++;
                        paintTile(bgImageGraphics, tile, srcRects[6], dstRects[6], style.backgroundImage);
                        dstRects[7].bottom++;
                        paintTileRepeat(bgImageGraphics, tile, srcRects[7], scaleX, 1, dstRects[7], style.backgroundImage);
                        dstRects[8].bottom++;
                        paintTile(bgImageGraphics, tile, srcRects[8], dstRects[8], style.backgroundImage);
                    }
                    else {
                        paintTile(bgImageGraphics, tile, srcRects[0], dstRects[0], style.backgroundImage);
                        paintTile(bgImageGraphics, tile, srcRects[1], dstRects[1], style.backgroundImage);
                        paintTile(bgImageGraphics, tile, srcRects[2], dstRects[2], style.backgroundImage);
                        
                        srcRects[3].bottom--;
                        paintTile(bgImageGraphics, tile, srcRects[3], dstRects[3], style.backgroundImage);
                        
                        srcRects[4].bottom--;
                        paintTile(bgImageGraphics, tile, srcRects[4], dstRects[4], style.backgroundImage);
                        
                        srcRects[5].bottom--;
                        paintTile(bgImageGraphics, tile, srcRects[5], dstRects[5], style.backgroundImage);
                        
                        dstRects[6].bottom++;
                        paintTile(bgImageGraphics, tile, srcRects[6], dstRects[6], style.backgroundImage);
                        dstRects[7].bottom++;
                        paintTile(bgImageGraphics, tile, srcRects[7], dstRects[7], style.backgroundImage);
                        dstRects[8].bottom++;
                        paintTile(bgImageGraphics, tile, srcRects[8], dstRects[8], style.backgroundImage);
                    }
                } else {
                    var scaleX:Float = 1;
                    var scaleY:Float = 1;
                    
                    if (style.backgroundImageRepeat == null || style.backgroundImageRepeat == "stretch") {
                        scaleX = w / trc.width;
                        scaleY = h / trc.height;
                    }
                    else {
                        if (style.backgroundWidth != null) {
                            scaleX = style.backgroundWidth / trc.width;
                        } else if (style.backgroundWidthPercent != null) {
                            scaleX = ((w / trc.width) * style.backgroundWidthPercent) / 100;
                        }
                        if (style.backgroundHeight != null) {
                            scaleY = style.backgroundHeight / trc.height;
                        } else if (style.backgroundHeightPercent != null) {
                            scaleY = ((h / trc.height) * style.backgroundHeightPercent) / 100;
                        }
                    }
                    
                    if (style.backgroundImageRepeat == "repeat") {
                        paintTileRepeat(bgImageGraphics, tile, trc, scaleX, scaleY, new Rectangle(0, 0, w, h), style.backgroundImage);
                    }
                    else {
                        paintTile(bgImageGraphics, tile, trc, new Rectangle(0, 0, trc.width * scaleX, trc.height * scaleY), style.backgroundImage);
                    }
                }
            });
        }
        
        if (borderAlpha > 0) {
            if (isCircle) {
                styleGraphics.lineStyle(2, borderColor.left, borderAlpha);
                styleGraphics.drawCircle(w / 2, h / 2, w / 2, Std.int(w));
                styleGraphics.endFill();
            } else if (borderRadius == 0) {
                if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                    styleGraphics.lineStyle();
                    styleGraphics.beginFill(borderColor.left, borderAlpha);
                    styleGraphics.lineTo(0, 0);
                    styleGraphics.lineTo(borderSize.left, borderSize.top);
                    styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                    styleGraphics.lineTo(0, h);
                    styleGraphics.endFill();
                }
                
                if (style.borderRightSize != null && style.borderRightSize > 0) {
                    styleGraphics.lineStyle();
                    styleGraphics.beginFill(borderColor.right, borderAlpha);
                    styleGraphics.lineTo(w, 0);
                    styleGraphics.lineTo(w, h);
                    styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                    styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                    styleGraphics.endFill();
                }
                
                if (style.borderTopSize != null && style.borderTopSize > 0) {
                    styleGraphics.lineStyle();
                    styleGraphics.beginFill(borderColor.top, borderAlpha);
                    styleGraphics.lineTo(0, 0);
                    styleGraphics.lineTo(w, 0);
                    styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                    styleGraphics.lineTo(borderSize.left, borderSize.top);
                    styleGraphics.endFill();
                }
                
                if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                    styleGraphics.lineStyle();
                    styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                    styleGraphics.lineTo(0, h);
                    styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                    styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                    styleGraphics.lineTo(w, h);
                    styleGraphics.endFill();
                }
            } else { // Border radius != 0
                // Left
                if (borderSize.left != 0) {
                    // Left-Top corner
                    if (borderSize.left == borderSize.top) {
                        if (borderRadius <= borderSize.left) {
                            // Left
                            styleGraphics.beginFill(borderColor.left, borderAlpha);
                            styleGraphics.drawPie(borderRadius, borderRadius, borderRadius, Math.PI, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(0, borderRadius);
                            styleGraphics.lineTo(borderRadius, borderRadius);
                            styleGraphics.lineTo(borderSize.left, borderSize.top);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(0, h * 0.5);
                            styleGraphics.endFill();
                            // Top
                            styleGraphics.beginFill(borderColor.top, borderAlpha);
                            styleGraphics.drawPie(borderRadius, borderRadius, borderRadius, Math.PI * 1.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(borderSize.left, borderSize.top);
                            styleGraphics.lineTo(borderRadius, borderRadius);
                            styleGraphics.endFill();
                        } else {
                            var innerRadius = borderRadius - borderSize.left;
                            // Left
                            styleGraphics.beginFill(borderColor.left, borderAlpha);
                            styleGraphics.drawPieInner(borderRadius, borderRadius, borderRadius, innerRadius, Math.PI, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(0, borderRadius);
                            styleGraphics.lineTo(borderSize.left, borderRadius);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(0, h * 0.5);
                            styleGraphics.endFill();
                            // Top
                            styleGraphics.beginFill(borderColor.top, borderAlpha);
                            styleGraphics.drawPieInner(borderRadius, borderRadius, borderRadius, innerRadius, Math.PI * 1.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(borderRadius, borderSize.top);
                            styleGraphics.endFill();
                        }
                    } else {
                        styleGraphics.beginFill(borderColor.left, borderAlpha);
                        if (borderRadius <= borderSize.left || borderRadius <= borderSize.top) {
                            drawUnevenBordersCurve(styleGraphics, borderRadius, borderRadius, borderRadius,
                                                    Math.PI, Math.PI * 0.5 * borderSize.left / (borderSize.left + borderSize.top));                                    
                            styleGraphics.lineTo(borderSize.left, borderSize.top);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(0, h * 0.5);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, borderRadius, borderRadius, borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.top,
                                                    Math.PI, Math.PI * 0.5 * borderSize.left / (borderSize.left + borderSize.top));
                            styleGraphics.moveTo(0, borderRadius);
                            styleGraphics.lineTo(borderSize.left, borderRadius);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(0, h * 0.5);
                        }
                        styleGraphics.endFill();
                    }
                    // Left-Bottom corner
                    if (borderSize.left == borderSize.bottom) {
                        if (borderRadius <= borderSize.left) {
                            // Left
                            styleGraphics.beginFill(borderColor.left, borderAlpha);
                            styleGraphics.drawPie(borderRadius, h - borderRadius, borderRadius, Math.PI * 0.75, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(0, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h - borderRadius);
                            styleGraphics.lineTo(0, h - borderRadius);
                            styleGraphics.endFill();
                            // Bottom
                            styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                            styleGraphics.drawPie(borderRadius, h - borderRadius, borderRadius, Math.PI * 0.5, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h - borderRadius);
                            styleGraphics.lineTo(borderRadius, h);
                            styleGraphics.endFill();
                        } else {
                            var innerRadius = borderRadius - borderSize.left;
                            // Left
                            styleGraphics.beginFill(borderColor.left, borderAlpha);
                            styleGraphics.drawPieInner(borderRadius, h - borderRadius, borderRadius, innerRadius, Math.PI * 0.75, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(0, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h - borderRadius);
                            styleGraphics.lineTo(0, h - borderRadius);
                            styleGraphics.endFill();
                            // Bottom
                            styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                            styleGraphics.drawPieInner(borderRadius, h - borderRadius, borderRadius, innerRadius, Math.PI * 0.5, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h);
                            styleGraphics.endFill();
                        }
                    } else {
                        styleGraphics.beginFill(borderColor.left, borderAlpha);
                        if (borderRadius <= borderSize.left || borderRadius <= borderSize.bottom) {
                            drawUnevenBordersCurve(styleGraphics, borderRadius, h - borderRadius, borderRadius,
                                                    Math.PI * (0.5 + 0.5 * borderSize.bottom / (borderSize.left + borderSize.bottom)),
                                                    Math.PI * 0.5 * borderSize.left / (borderSize.left + borderSize.bottom));
                            styleGraphics.lineTo(0, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, borderRadius, h - borderRadius, borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.bottom,
                                                    Math.PI * (0.5 + 0.5 * borderSize.bottom / (borderSize.left + borderSize.bottom)),
                                                    Math.PI * 0.5 * borderSize.left / (borderSize.left + borderSize.bottom));
                            styleGraphics.moveTo(0, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h * 0.5);
                            styleGraphics.lineTo(borderSize.left, h - borderRadius);
                            styleGraphics.lineTo(0, h - borderRadius);
                        }
                        styleGraphics.endFill();
                    }
                }

                // Top
                if(borderSize.top != 0) {
                    // Left-Top corner
                    if (borderSize.left != borderSize.top) {
                        styleGraphics.beginFill(borderColor.top, borderAlpha);
                        if (borderRadius <= borderSize.left || borderRadius <= borderSize.top) {
                            drawUnevenBordersCurve(styleGraphics, borderRadius, borderRadius, borderRadius,
                                                    Math.PI * (1 + 0.5 * borderSize.left / (borderSize.left + borderSize.top)),
                                                    Math.PI * 0.5 * borderSize.top / (borderSize.left + borderSize.top));                                
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(borderSize.left, borderSize.top);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, borderRadius, borderRadius, borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.top,
                                                    Math.PI * (1 + 0.5 * borderSize.left / (borderSize.left + borderSize.top)),
                                                    Math.PI * 0.5 * borderSize.top / (borderSize.left + borderSize.top));
                            styleGraphics.moveTo(borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(borderRadius, borderSize.top);
                        }
                        styleGraphics.endFill();
                    }
                    // Right-Top corner
                    if (borderSize.right != borderSize.top) {
                        styleGraphics.beginFill(borderColor.top, borderAlpha);
                        if (borderRadius <= borderSize.right || borderRadius <= borderSize.top) {
                            drawUnevenBordersCurve(styleGraphics, w - borderRadius, borderRadius, borderRadius,
                                                    Math.PI * -0.5, Math.PI * 0.5 * borderSize.top / (borderSize.right + borderSize.top));
                            styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(w * 0.5, 0);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, w - borderRadius, borderRadius, borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.top,
                                                    Math.PI * -0.5, Math.PI * 0.5 * borderSize.top / (borderSize.right + borderSize.top));
                            styleGraphics.moveTo(w - borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(w - borderRadius, borderSize.top);
                        }
                        styleGraphics.endFill();
                    }
                }

                // Right
                if(borderSize.right != 0) {
                    // Right-Top corner
                    if (borderSize.right == borderSize.top) {
                        if (borderRadius <= borderSize.right) {
                            // Right
                            styleGraphics.beginFill(borderColor.right, borderAlpha);
                            styleGraphics.drawPie(w - borderRadius, borderRadius, borderRadius, Math.PI * -0.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w, borderRadius);
                            styleGraphics.lineTo(w - borderRadius, borderRadius);
                            styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w, h * 0.5);
                            styleGraphics.endFill();
                            // Top
                            styleGraphics.beginFill(borderColor.top, borderAlpha);
                            styleGraphics.drawPie(w - borderRadius, borderRadius, borderRadius, Math.PI * -0.5, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w - borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                            styleGraphics.lineTo(w - borderRadius, borderRadius);
                            styleGraphics.endFill();
                        } else {
                            var innerRadius = borderRadius - borderSize.right;
                            // Right
                            styleGraphics.beginFill(borderColor.right, borderAlpha);
                            styleGraphics.drawPieInner(w - borderRadius, borderRadius, borderRadius, innerRadius, Math.PI * -0.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w, borderRadius);
                            styleGraphics.lineTo(w - borderSize.right, borderRadius);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w, h * 0.5);
                            styleGraphics.endFill();
                            // Top
                            styleGraphics.beginFill(borderColor.top, borderAlpha);
                            styleGraphics.drawPieInner(w - borderRadius, borderRadius, borderRadius, innerRadius, Math.PI * -0.5, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w - borderRadius, 0);
                            styleGraphics.lineTo(w * 0.5, 0);
                            styleGraphics.lineTo(w * 0.5, borderSize.top);
                            styleGraphics.lineTo(w - borderRadius, borderSize.top);
                            styleGraphics.endFill();
                        }
                    } else {
                        styleGraphics.beginFill(borderColor.right, borderAlpha);
                        if (borderRadius <= borderSize.right || borderRadius <= borderSize.top) {
                            drawUnevenBordersCurve(styleGraphics, w - borderRadius, borderRadius, borderRadius,
                                                    Math.PI * (-0.5 + 0.5 * borderSize.top / (borderSize.right + borderSize.top)),
                                                    Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.top));
                            styleGraphics.lineTo(w, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, borderSize.top);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, w - borderRadius, borderRadius, borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.top,
                                                    Math.PI * (-0.5 + 0.5 * borderSize.top / (borderSize.right + borderSize.top)),
                                                    Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.top));
                            styleGraphics.moveTo(w, borderRadius);
                            styleGraphics.lineTo(w - borderSize.right, borderRadius);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w, h * 0.5);
                        }
                        styleGraphics.endFill();
                    }
                    // Bottom-Right corner
                    if (borderSize.right == borderSize.bottom) {
                        if (borderRadius <= borderSize.right) {
                            // Right
                            styleGraphics.beginFill(borderColor.right, borderAlpha);
                            styleGraphics.drawPie(w - borderRadius, h - borderRadius, borderRadius, 0, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h - borderRadius);
                            styleGraphics.lineTo(w, h - borderRadius);
                            styleGraphics.endFill();
                            // Bottom
                            styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                            styleGraphics.drawPie(w - borderRadius, h - borderRadius, borderRadius, Math.PI * 0.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h - borderRadius);
                            styleGraphics.lineTo(w - borderRadius, h);
                            styleGraphics.endFill();
                        } else {
                            var innerRadius = borderRadius - borderSize.right;
                            // Right
                            styleGraphics.beginFill(borderColor.right, borderAlpha);
                            styleGraphics.drawPieInner(w - borderRadius, h - borderRadius, borderRadius, innerRadius, 0, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h - borderRadius);
                            styleGraphics.lineTo(w, h - borderRadius);
                            styleGraphics.endFill();
                            // Bottom
                            styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                            styleGraphics.drawPieInner(w - borderRadius, h - borderRadius, borderRadius, innerRadius, Math.PI * 0.25, Math.PI * 0.25, 10);
                            styleGraphics.lineTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h);
                            styleGraphics.endFill();
                        }
                    } else {
                        styleGraphics.beginFill(borderColor.right, borderAlpha);
                        if (borderRadius <= borderSize.right || borderRadius <= borderSize.bottom) {
                            drawUnevenBordersCurve(styleGraphics, w - borderRadius, h - borderRadius, borderRadius,
                                                    0, Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.bottom));
                            styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w, h * 0.5);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, w - borderRadius, h - borderRadius, borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.bottom,
                                                    0, Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.bottom));
                            styleGraphics.moveTo(w, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h * 0.5);
                            styleGraphics.lineTo(w - borderSize.right, h - borderRadius);
                            styleGraphics.lineTo(w, h - borderRadius);
                        }
                        styleGraphics.endFill();
                    }
                }

                // Bottom
                if(borderSize.bottom != 0) {
                    // Left-Bottom corner
                    if (borderSize.left != borderSize.bottom) {
                        styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                        if (borderRadius <= borderSize.left || borderRadius <= borderSize.bottom) {
                            drawUnevenBordersCurve(styleGraphics, borderRadius, h - borderRadius, borderRadius,
                                                    Math.PI * 0.5, Math.PI * 0.5 * borderSize.bottom / (borderSize.left + borderSize.bottom));
                            styleGraphics.lineTo(borderSize.left, h - borderSize.bottom);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(w * 0.5, h);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, borderRadius, h - borderRadius, borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.bottom,
                                                    Math.PI * 0.5, Math.PI * 0.5 * borderSize.bottom / (borderSize.left + borderSize.bottom));
                            styleGraphics.moveTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h - borderSize.bottom);
                            styleGraphics.lineTo(borderRadius, h);
                        }
                        styleGraphics.endFill();
                    }
                    // Right-Bottom corner
                    if (borderSize.right != borderSize.bottom) {
                        styleGraphics.beginFill(borderColor.bottom, borderAlpha);
                        if (borderRadius <= borderSize.right || borderRadius <= borderSize.bottom) {
                            drawUnevenBordersCurve(styleGraphics, w - borderRadius, h - borderRadius, borderRadius,
                                                    Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.bottom),
                                                    Math.PI * 0.5 * borderSize.bottom / (borderSize.right + borderSize.bottom));
                            styleGraphics.lineTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderSize.right, h - borderSize.bottom);
                        } else {
                            drawUnevenBordersCorner(styleGraphics, w - borderRadius, h - borderRadius, borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.bottom,
                                                    Math.PI * 0.5 * borderSize.right / (borderSize.right + borderSize.bottom),
                                                    Math.PI * 0.5 * borderSize.bottom / (borderSize.right + borderSize.bottom));
                            styleGraphics.moveTo(w * 0.5, h);
                            styleGraphics.lineTo(w * 0.5, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h - borderSize.bottom);
                            styleGraphics.lineTo(w - borderRadius, h);
                        }
                        styleGraphics.endFill();
                    }
                }
            }
        } // End borders
    }
    
    private static function paintTile(g:Graphics, tile:Tile, src:Rectangle, dst:Rectangle, backgroundImage:String) {
        var scaleX = dst.width / src.width;
        var scaleY = dst.height / src.height;
        var sub = TileCache.get(backgroundImage + "_" + scaleX + "_" + scaleY, src);
        if (sub == null) {
            sub = tile.sub(src.left * scaleX, src.top * scaleY, src.width, src.height);
            TileCache.set(backgroundImage + "_" + scaleX + "_" + scaleY, sub, src);
        }
        g.smooth = true;
        g.beginTileFill(dst.left, dst.top, scaleX, scaleY, sub);
        g.drawRect(dst.left, dst.top, dst.width, dst.height);
        g.endFill();
    }
  
    // Used to repeat part (src) of an image (tile) with a given scale (srcScaleX, srcScaleY) inside a target (dst)
    private static function paintTileRepeat(g:Graphics, tile:Tile, src:Rectangle, srcScaleX:Float, srcScaleY:Float, dst:Rectangle, backgroundImage:String) {
        var scaledw = srcScaleX * src.width;
        var scaledh = srcScaleY * src.height;
        var wCount = dst.width / scaledw;
        var hCount = dst.height / scaledh;
        
        var iwCount = Math.ceil(wCount);
        var ihCount = Math.ceil(hCount);
        
        var lastw = iwCount - 1;
        var lasth = ihCount - 1;
        
        // Full images
        for (iwCurr in 0...lastw) {
            for (ihCurr in 0...lasth) {
                paintTile(g, tile, src, new Rectangle(dst.left + iwCurr * scaledw, dst.top + ihCurr * scaledh, scaledw, scaledh), backgroundImage);
            }
        }
        
        var localRect = src.copy();
        // Images clipped in width
        var clippedw = (wCount - lastw) * scaledw;
        localRect.width = (wCount - lastw) * src.width;
        for (ihCurr in 0...lasth) {
            paintTile(g, tile, localRect, new Rectangle(dst.left + lastw * scaledw, dst.top + ihCurr * scaledh, clippedw, scaledh), backgroundImage);
        }
        
        // Images clipped in height
        var clippedh = (hCount - lasth) * scaledh;
        localRect.width = src.width;
        localRect.height = (hCount - lasth) * src.height;
        for (iwCurr in 0...lastw) {
            paintTile(g, tile, localRect, new Rectangle(dst.left + iwCurr * scaledw, dst.top + lasth * scaledh, scaledw, clippedh), backgroundImage);
        }
        
        // Image clipped in both
        localRect.width = (wCount - lastw) * src.width;
        if (localRect.width > 1 && localRect.height > 1) {
            paintTile(g, tile, localRect, new Rectangle(dst.left + lastw * scaledw, dst.top + lasth * scaledh, clippedw, clippedh), backgroundImage);
        }
    }

    private static function drawUnevenBordersCorner(graphics:Graphics, cx:Float, cy:Float, radius:Float, startInnerRadius:Float, endInnerRadius:Float, angleStart:Float, angleLength:Float) {
        var nsegments = 10;
        var angleOffset = angleLength / (nsegments - 1);

        graphics.lineTo(cx + Math.cos(angleStart) * startInnerRadius, cy + Math.sin(angleStart) * endInnerRadius);
        var a;
        // Circle on the outside
        for (i in 0...nsegments) {
            a = i * angleOffset + angleStart;
            graphics.lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
        }
        // Ellipse on the inside
        graphics.lineTo(cx + Math.cos(angleStart + angleLength) * startInnerRadius, cy + Math.sin(angleStart + angleLength) * endInnerRadius);
        for (i in 0...nsegments) {
            a = (nsegments - 1 - i) * angleOffset + angleStart;
            graphics.lineTo(cx +  Math.cos(a) * startInnerRadius, cy + Math.sin(a) * endInnerRadius);
        }
    }

    private static function drawUnevenBordersCurve(graphics:Graphics, cx:Float, cy:Float, radius:Float, angleStart:Float, angleLength:Float) {
        var nsegments = 10;
        var angleOffset = angleLength / (nsegments - 1);
        var a;
        for (i in 0...nsegments) {
            a = i * angleOffset + angleStart;
            graphics.lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
        }
    }

    private static function drawRoundedBackground(graphics:Graphics, w:Float, h:Float, borderSize:Rectangle, borderRadius:Float) {
        // Left-Top
        if (borderRadius <= borderSize.left || borderRadius <= borderSize.top) {
            graphics.lineTo(borderSize.left, borderSize.top);
        } else {
            graphics.lineTo(borderSize.left, borderRadius);
            drawBackgroundCorner(graphics, borderRadius, borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.top, Math.PI, Math.PI * 0.5);
        }
        // Top-Right
        if (borderRadius <= borderSize.right || borderRadius <= borderSize.top) {
            graphics.lineTo(w - borderSize.right, borderSize.top);
        } else {
            graphics.lineTo(w - borderRadius, borderSize.top);
            drawBackgroundCorner(graphics, w - borderRadius, borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.top, -Math.PI * 0.5, Math.PI * 0.5);
        }
        // Right-Bottom
        if (borderRadius <= borderSize.right || borderRadius <= borderSize.bottom) {
            graphics.lineTo(w - borderSize.right, h - borderSize.bottom);
        } else {
            graphics.lineTo(w - borderSize.right, h - borderRadius);
            drawBackgroundCorner(graphics, w - borderRadius, h - borderRadius, borderRadius - borderSize.right, borderRadius - borderSize.bottom, 0, Math.PI * 0.5);
        }
        // Bottom-Left
        if (borderRadius <= borderSize.left || borderRadius <= borderSize.bottom) {
            graphics.lineTo(borderSize.left, h - borderSize.bottom);
        } else {
            graphics.lineTo(borderRadius, h - borderSize.bottom);
            drawBackgroundCorner(graphics, borderRadius, h - borderRadius, borderRadius - borderSize.left, borderRadius - borderSize.bottom, Math.PI * 0.5, Math.PI * 0.5);
        }
    }

    private static inline function drawBackgroundCorner(graphics:Graphics, cx:Float, cy:Float, startRadius:Float, endRadius:Float, angleStart:Float, angleLength:Float) {
        var nsegments = startRadius != endRadius ? 200 : 100;
        var angleOffset = angleLength / (nsegments - 1);
        var a;
        for (i in 0...nsegments) {
            a = i * angleOffset + angleStart;
            graphics.lineTo(cx +  Math.cos(a) * startRadius, cy + Math.sin(a) * endRadius);
        }
    }
}
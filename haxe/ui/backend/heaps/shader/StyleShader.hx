package haxe.ui.backend.heaps.shader;

class StyleShader extends hxsl.Shader {

    static var SRC = {
        @:import h3d.shader.Base2d;

        @param var size : Vec2;
        @param var halfSize : Vec2;
        @param var radius : Float;

        //Background
        @param var backgroundColor : Vec4;
        @param var backgroundColorEnd : Vec4;
        @param var backgroundDirection : Vec2;
        @param var backgroundImage : Sampler2D;
        @param var backgroundImageUV : Vec4;    //uOffset, vOffset, uScale, vScale
        @param var backgroundImageSliceBox : Vec4; //left, top, right, bottom
        @param var backgroundImageSliceTexture : Vec4; //left, top, right, bottom

        //Border
        @param var borderColor : Vec4;
        @param var borderThickness : Float;
        @param var borderColorLeft : Vec4;
        @param var borderThicknessLeft : Float;
        @param var borderColorRight : Vec4;
        @param var borderThicknessRight : Float;
        @param var borderColorTop : Vec4;
        @param var borderThicknessTop : Float;
        @param var borderColorBottom : Vec4;
        @param var borderThicknessBottom : Float;

        //Flags
        @const var hasRadius : Bool;
        @const var hasFullBorder : Bool;
        @const var hasBorderLeft : Bool;
        @const var hasBorderRight : Bool;
        @const var hasBorderTop : Bool;
        @const var hasBorderBottom : Bool;
        @const var hasBackgroundImage : Bool;
        @const var hasBackgroundImageSlice : Bool;
        @const var hasBackgroundGradient : Bool;

        function roundedBox(pos:Vec2, size:Vec2, r:Float):Float
        {
            return clamp(length(max(abs(pos) - size + r, 0.0)) - r, 0.0, 1.0);
        }

        function box(uv:Vec2, size:Vec2, thickness:Float):Float
        {
            var t = thickness / size;
            var bl:Vec2 = step(t, uv);          //bottom-left
            var tr:Vec2 = step(t, 1.0 - uv);    //top-right
            return bl.x * bl.y * tr.x * tr.y;
        }

        function borderLeft(uv:Vec2, size:Vec2, thickness:Float):Float
        {
            return step(thickness / size.x, uv.x);
        }

        function borderRight(uv:Vec2, size:Vec2, thickness:Float):Float
        {
            return step(thickness / size.x, 1.0 - uv.x);
        }

        function borderTop(uv:Vec2, size:Vec2, thickness:Float):Float
        {
            return step(thickness / size.y, 1.0 - uv.y);
        }

        function borderBottom(uv:Vec2, size:Vec2, thickness:Float):Float
        {
            return step(thickness / size.y, uv.y);
        }

        function map(value:Float, fromMin:Float, fromMax:Float, toMin:Float, toMax:Float):Float {
            return (value - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin;
        }

        function processSliceAxis(coord:Float, textureRange:Vec2, boxRange:Vec2):Float {
            if (coord < boxRange.x)
                return map(coord, 0, boxRange.x, 0, textureRange.x) ;
            else if (coord < boxRange.y)
                return map(coord,  boxRange.x, boxRange.y, textureRange.x, textureRange.y);
            else
                return map(coord, boxRange.y, 1, textureRange.y, 1);
        }

        function fragment() {
            var bgColor:Vec4;
            if (hasBackgroundImage) {
                var uv:Vec2 = (hasBackgroundImageSlice) ? vec2(
                    processSliceAxis(input.position.x, backgroundImageSliceTexture.xz, backgroundImageSliceBox.xz),
                    processSliceAxis(input.position.y, backgroundImageSliceTexture.yw, backgroundImageSliceBox.yw))
                : input.position;

                bgColor = backgroundImage.get((uv + backgroundImageUV.xy) * backgroundImageUV.zw);
            } else if (hasBackgroundGradient) {
                bgColor = mix(backgroundColor, backgroundColorEnd, dot(input.position, backgroundDirection));
            } else {
                bgColor = backgroundColor;
            }

            if (hasRadius) {
                var baseColor:Vec4 = vec4(0.0, 0.0, 0.0, 0.0);
                var pixelCoord:Vec2 = input.position * size;
                var pos:Vec2 = pixelCoord - halfSize;
                var intensity:Float = roundedBox(pos, halfSize, radius);
                if (hasFullBorder) {
                    var intensityIn:Float = roundedBox(pos, halfSize - borderThickness, max(radius - borderThickness, 0.0));
                    pixelColor = mix(bgColor, mix(borderColor, baseColor, intensity), intensityIn);
                } else {
                    pixelColor = mix(bgColor, baseColor, intensity);
                }
            } else {
                if (hasFullBorder) {
                    var intensityBorder:Float = box(input.position, size, borderThickness);
                    pixelColor = mix(borderColor, bgColor, intensityBorder);
                } else if (hasBorderLeft || hasBorderRight || hasBorderTop || hasBorderBottom) {
                    var intensityBorder:Float = 1.0;
                    var borderColor:Vec4 = bgColor;
                    if (hasBorderLeft) {
                        var intensityBorderLeft:Float = borderLeft(input.position, size, borderThicknessLeft);
                        borderColor = mix(borderColor, borderColorLeft, step(intensityBorderLeft, 0.5));
                        intensityBorder *= intensityBorderLeft;
                    }
                    if (hasBorderRight) {
                        var intensityBorderRight:Float = borderRight(input.position, size, borderThicknessRight);
                        borderColor = mix(borderColor, borderColorRight, step(intensityBorderRight, 0.5));
                        intensityBorder *= intensityBorderRight;
                    }
                    if (hasBorderTop) {
                        var intensityBorderTop:Float = borderTop(input.position, size, borderThicknessTop);
                        borderColor = mix(borderColor, borderColorTop, step(intensityBorderTop, 0.5));
                        intensityBorder *= intensityBorderTop;
                    }
                    if (hasBorderBottom) {
                        var intensityBorderBottom:Float = borderBottom(input.position, size, borderThicknessBottom);
                        borderColor = mix(borderColor, borderColorBottom, step(intensityBorderBottom, 0.5));
                        intensityBorder *= intensityBorderBottom;
                    }

                    pixelColor = mix(borderColor, bgColor, intensityBorder);
                } else {
                    pixelColor = bgColor;
                }
            }
        }
    };

}
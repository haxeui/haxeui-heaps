package haxe.ui.backend.heaps.shader;

class ScissorShader extends hxsl.Shader {
    static var SRC = {
        @:import h3d.shader.Base2d;

        @param var xMin : Float;
        @param var xMax : Float;
        @param var yMin : Float;
        @param var yMax : Float;

        function fragment() {
            if (input.position.x < xMin || input.position.x > xMax ||
                input.position.y < yMin || input.position.y > yMax)
            {
                discard;
            }
        }

    };

    public function new() {
        super();
    }

    public function setTo(xMin:Float, xMax:Float, yMin:Float, yMax:Float, spriteWidth:Float, spriteHeight:Float) {
        this.xMin = xMin / spriteWidth;
        this.xMax = xMax / spriteWidth;
        this.yMin = yMin / spriteHeight;
        this.yMax = yMax / spriteHeight;
    }
}
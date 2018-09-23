package haxe.ui.backend.macros;

import haxe.macro.Expr;

class HaxeUIMacros {
    macro public static function buildComponent():Array<Field> {
        var pos = haxe.macro.Context.currentPos();
        var fields:Array<Field> = haxe.macro.Context.getBuildFields();

        var i:Int = fields.length;
        while(--i >= 0) {
            var f:Field = fields[i];
            switch(f.name) {
                case "color":
                    fields.remove(f);
            }
        }

        return fields;
    }

    /*static private function replaceWithCode(f:Field, code:String) {
        var e:Expr = haxe.macro.Context.parseInlineString(code, f.pos);
        var fn = switch (e).expr {
            case EFunction(_, f): f;
            case _: throw "false";
        }
        f.kind = FFun(fn);
    }*/
}
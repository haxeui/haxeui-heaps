package haxe.ui.backend.macros;

import haxe.macro.Expr;

class HeapsMacros {
    macro public static function removeInline(propNames:Array<String>):Array<Field> {
        var pos = haxe.macro.Context.currentPos();
        var fields:Array<Field> = haxe.macro.Context.getBuildFields();

        for(f in fields)
        {
            if(propNames.indexOf(f.name) != -1){
                f.access = [APrivate];
            }
        }

        return fields;
    }
}

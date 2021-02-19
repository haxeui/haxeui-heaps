package haxe.ui.backend.heaps;

import h2d.filter.Filter;

class FilterConverter {
    public static function convertFilter(input:haxe.ui.filters.Filter):Filter {
        if (input == null) {
            return null;
        }
        
        var output:Filter = null;
        
        if ((input is haxe.ui.filters.DropShadow)) {
            var inputDropShadow:haxe.ui.filters.DropShadow = cast(input, haxe.ui.filters.DropShadow);
            var dropShadow = new h2d.filter.DropShadow(inputDropShadow.distance, 0.785, inputDropShadow.color, inputDropShadow.alpha, 1, 1, 1, true);
            //output = dropShadow;
        }
        
        return output;
    }
}
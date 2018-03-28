package haxe.ui.backend.heaps;


class EventMapper {
    public static var HAXEUI_TO_HEAPS:Map<String, String> = [
        haxe.ui.core.MouseEvent.MOUSE_MOVE => EventType.MOUSE_MOVE,
        haxe.ui.core.MouseEvent.MOUSE_OVER => EventType.MOUSE_OVER,
        haxe.ui.core.MouseEvent.MOUSE_OUT => EventType.MOUSE_OUT,
        haxe.ui.core.MouseEvent.MOUSE_DOWN => EventType.MOUSE_DOWN,
        haxe.ui.core.MouseEvent.MOUSE_UP => EventType.MOUSE_UP,
        haxe.ui.core.MouseEvent.MOUSE_WHEEL => EventType.MOUSE_WHEEL,
        haxe.ui.core.MouseEvent.CLICK => EventType.CLICK,

        haxe.ui.core.KeyboardEvent.KEY_DOWN => EventType.KEY_DOWN,
        haxe.ui.core.KeyboardEvent.KEY_UP => EventType.KEY_UP
    ];

    /*public static var HEAPS_TO_HAXEUI:Map<String, String> = [
        EventType.MOUSE_MOVE => haxe.ui.core.MouseEvent.MOUSE_MOVE,
        EventType.MOUSE_OVER => haxe.ui.core.MouseEvent.MOUSE_OVER,
        EventType.MOUSE_OUT => haxe.ui.core.MouseEvent.MOUSE_OUT,
        EventType.MOUSE_DOWN => haxe.ui.core.MouseEvent.MOUSE_DOWN,
        EventType.MOUSE_UP => haxe.ui.core.MouseEvent.MOUSE_UP,
        EventType.MOUSE_WHEEL => haxe.ui.core.MouseEvent.MOUSE_WHEEL,
        EventType.CLICK => haxe.ui.core.MouseEvent.CLICK,

        EventType.KEY_DOWN => haxe.ui.core.KeyboardEvent.KEY_DOWN,
        EventType.KEY_UP => haxe.ui.core.KeyboardEvent.KEY_UP
    ];*/
}
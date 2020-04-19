package haxe.ui.backend.heaps;

class EventMapper {
    public static var HAXEUI_TO_HEAPS:Map<String, String> = [
        haxe.ui.events.MouseEvent.MOUSE_MOVE => EventType.MOUSE_MOVE,
        haxe.ui.events.MouseEvent.MOUSE_OVER => EventType.MOUSE_OVER,
        haxe.ui.events.MouseEvent.MOUSE_OUT => EventType.MOUSE_OUT,
        haxe.ui.events.MouseEvent.MOUSE_DOWN => EventType.MOUSE_DOWN,
        haxe.ui.events.MouseEvent.MOUSE_UP => EventType.MOUSE_UP,
        haxe.ui.events.MouseEvent.MOUSE_WHEEL => EventType.MOUSE_WHEEL,
        haxe.ui.events.MouseEvent.CLICK => EventType.CLICK,

        haxe.ui.events.KeyboardEvent.KEY_DOWN => EventType.KEY_DOWN,
        haxe.ui.events.KeyboardEvent.KEY_UP => EventType.KEY_UP
    ];

    /*public static var HEAPS_TO_HAXEUI:Map<String, String> = [
        EventType.MOUSE_MOVE => haxe.ui.events.MouseEvent.MOUSE_MOVE,
        EventType.MOUSE_OVER => haxe.ui.events.MouseEvent.MOUSE_OVER,
        EventType.MOUSE_OUT => haxe.ui.events.MouseEvent.MOUSE_OUT,
        EventType.MOUSE_DOWN => haxe.ui.events.MouseEvent.MOUSE_DOWN,
        EventType.MOUSE_UP => haxe.ui.events.MouseEvent.MOUSE_UP,
        EventType.MOUSE_WHEEL => haxe.ui.events.MouseEvent.MOUSE_WHEEL,
        EventType.CLICK => haxe.ui.events.MouseEvent.CLICK,

        EventType.KEY_DOWN => haxe.ui.events.KeyboardEvent.KEY_DOWN,
        EventType.KEY_UP => haxe.ui.events.KeyboardEvent.KEY_UP
    ];*/
}
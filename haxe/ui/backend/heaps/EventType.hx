package haxe.ui.backend.heaps;

enum abstract EventType(String) from String to String {
    var MOUSE_MOVE = "onMove";
    var MOUSE_OVER = "onOver";
    var MOUSE_OUT = "onOut";
    var MOUSE_DOWN = "onPush";
    var MOUSE_UP = "onRelease";
    var MOUSE_WHEEL = "onWheel";
    var CLICK = "onClick";

    var KEY_DOWN = "onKeyDown";
    var KEY_UP = "onKeyUp";
}
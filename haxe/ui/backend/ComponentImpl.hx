package haxe.ui.backend;

import h2d.Interactive;
import h2d.Mask;
import h2d.Object;
import h2d.RenderContext;
import haxe.ui.backend.heaps.FilterConverter;
import haxe.ui.backend.heaps.MouseHelper;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.Screen;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import haxe.ui.util.MathUtil;

class ComponentImpl extends ComponentBase { 
    private var _eventMap:Map<String, UIEvent->Void>;
    
    static inline var INDEX_OFFSET = 1; // offset everything because 0th-child is always the style graphics container

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
        addChild(new Object()); // style graphics container
        //cast(this, Component).ready();
    }

    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left == null || top == null || left < 0 || top < 0) {
            return;
        }
        
        left = Std.int(left);
        top = Std.int(top);
        
        if (_mask == null) {
            this.x = left;
            this.y = top;
        } else {
            _mask.x = left;
            _mask.y = top;
        }
        if (_interactive != null) {
            _interactive.x = 0;
            _interactive.y = 0;
        }
    }
    
    private override function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        StyleHelper.apply(this, style, w, h);
        if (_interactive != null) {
            _interactive.width = w;
            _interactive.height = h;
        }
    }
    
    private override function handleVisibility(show:Bool) {
        visible = show;
    }
    
    private var _mask:Mask = null;
    private override function handleClipRect(value:Rectangle) {
        if (value != null) {
            if (_mask == null) {
                _mask = new Mask(Std.int(value.width), Std.int(value.height), this.parentComponent);
                _mask.addChild(this);
            }
            value.toInts();
            this.x = -value.left + 1;
            this.y = -value.top;
            _mask.x = left - 1;
            _mask.y = top;
            _mask.width = Std.int(value.width) + 1;
            _mask.height = Std.int(value.height);
        } else if (_mask != null) {
            _mask = null;
        }
    }
    
    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    public override function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            super.createTextDisplay(text);
            addChild(_textDisplay.sprite);
        }
        
        return _textDisplay;
    }

    public override function createTextInput(text:String = null):TextInput {
        if (_textInput == null) {
            super.createTextInput(text);
            addChild(_textInput.sprite);
        }
        
        return _textInput;
    }
    
    //***********************************************************************************************************
    // Image related
    //***********************************************************************************************************
    public override function createImageDisplay():ImageDisplay {
        if (_imageDisplay == null) {
            super.createImageDisplay();
            addChild(_imageDisplay.sprite);
        }
        
        return _imageDisplay;
    }
    
    public override function removeImageDisplay() {
        if (_imageDisplay != null) {
            removeChild(_imageDisplay.sprite);
            _imageDisplay.dispose();
            _imageDisplay = null;
        }
    }
    
    //***********************************************************************************************************
    // Display tree
    //***********************************************************************************************************
    
    private override function handleSetComponentIndex(child:Component, index:Int) {
        addChildAt(child, index + INDEX_OFFSET);
    }

    private override function handleAddComponent(child:Component):Component {
        addChild(child);
        return child;
    }

    private override function handleAddComponentAt(child:Component, index:Int):Component {
        addChildAt(child, index + INDEX_OFFSET);
        return child;
    }

    private override function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        removeChild(child);
        
        if (dispose == true) {
            child.dispose();
        }
        
        return child;
    }

    private override function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        var child = _children[index];
        if (child != null) {
            removeChild(child);

            if (dispose == true) {
                child.dispose();
            }
        }
        return child;
    }
    
    private function dispose() {
        removeChildren();
        _interactive = null;
        _mask = null;
        remove();
    }
    
    private override function applyStyle(style:Style) {
        /*
        if (style.cursor != null && style.cursor == "pointer") {
            cursor = Cursor.Button;
        } else if (cursor != hxd.Cursor.Default) {
            cursor = Cursor.Default;
        }
        */

        if (style.filter != null && style.filter.length > 0) {
            filter = FilterConverter.convertFilter(style.filter[0]);
        } else {
            filter = null;
        }

        if (style.hidden != null) {
            visible = !style.hidden;
        }

        if (style.opacity != null) {
            alpha = style.opacity;
        }
    }
    
    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    @:access(haxe.ui.core.Screen)
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_MOVE, listener);
                }
                
            case MouseEvent.MOUSE_OVER:
                if (_eventMap.exists(MouseEvent.MOUSE_OVER) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_OVER, listener);
                }
                
            case MouseEvent.MOUSE_OUT:
                if (_eventMap.exists(MouseEvent.MOUSE_OUT) == false) {
                    interactive = true;
                    _eventMap.set(MouseEvent.MOUSE_OUT, listener);
                }
                
            case MouseEvent.MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                }
                
            case MouseEvent.MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_UP, listener);
                }
                
            case MouseEvent.MOUSE_WHEEL:
                if (_eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    MouseHelper.notify(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                    _eventMap.set(MouseEvent.MOUSE_WHEEL, listener);
                }
                
            case MouseEvent.CLICK:
                if (_eventMap.exists(MouseEvent.CLICK) == false) {
                    interactive = true;
                    _eventMap.set(MouseEvent.CLICK, listener);

                    if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        _eventMap.set(MouseEvent.MOUSE_DOWN, null);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_UP, null);
                    }

                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_UP, null);
                    } 
                }
                
			case MouseEvent.DBL_CLICK:
                if (_eventMap.exists(MouseEvent.DBL_CLICK) == false) {
                    interactive = true;
                    _eventMap.set(MouseEvent.DBL_CLICK, listener);
					
                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onDoubleClick);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
                
            case MouseEvent.RIGHT_MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    interactive = true;
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                }
                
            case MouseEvent.RIGHT_CLICK:
                if (_eventMap.exists(MouseEvent.RIGHT_CLICK) == false) {
                    interactive = true;
                    _eventMap.set(MouseEvent.RIGHT_CLICK, listener);

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                    }
                }
        }
    }

    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OVER:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OUT:
                _eventMap.remove(type);

            case MouseEvent.MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
                
            case MouseEvent.MOUSE_WHEEL:
                _eventMap.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.CLICK:
                _eventMap.remove(type);
                
			case MouseEvent.DBL_CLICK:
                _eventMap.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_UP, __onDoubleClick);
                
            case MouseEvent.RIGHT_MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
                
            case MouseEvent.RIGHT_CLICK:
                _eventMap.remove(type);
        }
    }
    
    // lets cache certain items so we dont have to loop multiple times per frame
    private var _cachedScreenX:Null<Float> = null;
    private var _cachedScreenY:Null<Float> = null;
    private var _cachedClipComponent:Component = null;
    private var _cachedClipComponentNone:Null<Bool> = null;
    private var _cachedRootComponent:Component = null;
    
    private function clearCaches() {
        _cachedScreenX = null;
        _cachedScreenY = null;
        _cachedClipComponent = null;
        _cachedClipComponentNone = null;
        _cachedRootComponent = null;
    }
    
    private function cacheScreenPos() {
        if (_cachedScreenX != null && _cachedScreenY != null) {
            return;
        }
        
        var c:Component = cast(this, Component);
        var xpos:Float = 0;
        var ypos:Float = 0;
        while (c != null) {
            xpos += c.left;
            ypos += c.top;
            if (c.componentClipRect != null) {
                xpos -= c.componentClipRect.left;
                ypos -= c.componentClipRect.top;
            }
            c = c.parentComponent;
        }
        
        _cachedScreenX = xpos;
        _cachedScreenY = ypos;
    }
    
    private var screenX(get, null):Float;
    private function get_screenX():Float {
        cacheScreenPos();
        return _cachedScreenX;
    }

    private var screenY(get, null):Float;
    private function get_screenY():Float {
        cacheScreenPos();
        return _cachedScreenY;
    }

    private function findRootComponent():Component {
        if (_cachedRootComponent != null) {
            return _cachedRootComponent;
        }
        
        var c:Component = cast(this, Component);
        while (c.parentComponent != null) {
            c = c.parentComponent;
        }
        
        _cachedRootComponent = c;
        
        return c;
    }
    
    private function isRootComponent():Bool {
        return (findRootComponent() == this);
    }
    
    private function findClipComponent():Component {
        if (_cachedClipComponent != null) {
            return _cachedClipComponent;
        } else if (_cachedClipComponentNone == true) {
            return null;
        }
        
        var c:Component = cast(this, Component);
        var clip:Component = null;
        while (c != null) {
            if (c.componentClipRect != null) {
                clip = c;
                break;
            }
            c = c.parentComponent;
        }

        _cachedClipComponent = clip;
        if (clip == null) {
            _cachedClipComponentNone = true;
        }
        
        return clip;
    }
    
    @:access(haxe.ui.core.Component)
    private function inBounds(x:Float, y:Float):Bool {
        if (cast(this, Component).hidden == true) {
            return false;
        }

        var b:Bool = false;
        var sx = screenX * Toolkit.scaleX;
        var sy = screenY * Toolkit.scaleY;
        var cx = cast(this, Component).componentWidth * Toolkit.scaleX;
        var cy = cast(this, Component).componentHeight * Toolkit.scaleY;

        if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
            b = true;
        }

        // let make sure its in the clip rect too
        if (b == true) {
            var clip:Component = findClipComponent();
            if (clip != null) {
                b = false;
                var sx = (clip.screenX + clip.componentClipRect.left) * Toolkit.scaleX;
                var sy = (clip.screenY + clip.componentClipRect.top) * Toolkit.scaleY;
                var cx = clip.componentClipRect.width * Toolkit.scaleX;
                var cy = clip.componentClipRect.height * Toolkit.scaleY;
                if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
                    b = true;
                }
            }
        }
        return b;
    }
    
    private function isEventRelevant(children:Array<Component>, eventType:String):Bool {
        var relevant = false;
        for (c in children) {
            if (c == this) {
                relevant = true;
            }
            if (c.parentComponent == null) {
                break;
            }
        }
        
        return relevant;
    }

    private function getComponentsAtPoint(x:Float, y:Float, reverse:Bool = false):Array<Component> {
        var array:Array<Component> = new Array<Component>();
        for (r in Screen.instance.rootComponents) {
            findChildrenAtPoint(r, x, y, array);
        }
        
        if (reverse == true) {
            array.reverse();
        }
        
        return array;
    }

    private function findChildrenAtPoint(child:Component, x:Float, y:Float, array:Array<Component>) {
        if (child.inBounds(x, y) == true) {
            array.push(child);
        }
        for (c in child.childComponents) {
            findChildrenAtPoint(c, x, y, array);
        }
    }

    public function hasChildRecursive(parent:Component, child:Component):Bool {
        if (parent == child) {
            return true;
        }
        var r = false;
        for (t in parent.childComponents) {
            if (t == child) {
                r = true;
                break;
            }

            r = hasChildRecursive(t, child);
            if (r == true) {
                break;
            }
        }

        return r;
    }
    
    private override function sync(ctx:RenderContext) {
        super.sync(ctx);
        clearCaches();
    }
    
    private  override function onAdd() {
        super.onAdd();
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) == -1) {
            Screen.instance.rootComponents.push(cast this);
        }
        cast(this, Component).ready();
    }
    
    private override function onRemove() {
        super.onRemove();
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) != -1) {
            Screen.instance.rootComponents.remove(cast this);
        }
    }
    
    private var lastMouseX:Float = -1;
    private var lastMouseY:Float = -1;
    
	// For doubleclick detection
	private var _lastClickTime:Float = 0;
	private var _lastClickTimeDiff:Float = MathUtil.MAX_INT;
	private var _lastClickX:Float = -1;
	private var _lastClickY:Float = -1;
    
    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(event:MouseEvent) {
        var x = event.screenX;
        var y = event.screenY;
        lastMouseX = x;
        lastMouseY = y;

        var i = inBounds(x, y);
        if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
            return;
        }
        
        if (i == true) {
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_MOVE);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_MOVE);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
        
        if (i == true && _mouseOverFlag == false) {
            if (isEventRelevant(getComponentsAtPoint(x, y, true), MouseEvent.MOUSE_OVER)) {
                _mouseOverFlag = true;
                var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OVER);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OVER);
                    mouseEvent.screenX = x / Toolkit.scaleX;
                    mouseEvent.screenY = y / Toolkit.scaleY;
                    fn(mouseEvent);
                }
            }
        } else if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
    }    
    
    private var _mouseDownFlag:Bool = false;
    private var _mouseDownButton:Int = -1;
    private function __onMouseDown(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && _mouseDownFlag == false) {
            /*
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            */
            if (isEventRelevant(getComponentsAtPoint(x, y, true), MouseEvent.MOUSE_DOWN)) {
                _mouseDownFlag = true;
                _mouseDownButton = button;
                var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_DOWN: haxe.ui.events.MouseEvent.RIGHT_MOUSE_DOWN;
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.screenX = x / Toolkit.scaleX;
                    mouseEvent.screenY = y / Toolkit.scaleY;
                    fn(mouseEvent);
                }
            }
        }
    }

    private function __onMouseUp(event:MouseEvent) {
        var button:Int = _mouseDownButton;
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true) {
            /*
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            */
			
            if (_mouseDownFlag == true) {
                var type = button == 0 ? haxe.ui.events.MouseEvent.CLICK: haxe.ui.events.MouseEvent.RIGHT_CLICK;
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.screenX = x / Toolkit.scaleX;
                    mouseEvent.screenY = y / Toolkit.scaleY;
                    Toolkit.callLater(function() {
                        fn(mouseEvent);
                    });
                }
				
				if (type == haxe.ui.events.MouseEvent.CLICK) {
					_lastClickTimeDiff = Timer.stamp() - _lastClickTime;
					_lastClickTime = Timer.stamp();
					if (_lastClickTimeDiff >= 0.5) { // 0.5 seconds
						_lastClickX = x;
						_lastClickY = y;
					}
				}
            }

            _mouseDownFlag = false;
            var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_UP: haxe.ui.events.MouseEvent.RIGHT_MOUSE_UP;
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
        _mouseDownFlag = false;
    }
	
	private function __onDoubleClick(event:MouseEvent) {
        var button:Int = _mouseDownButton;
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && button == 0) {
            /*
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            */
			
            _mouseDownFlag = false;
			var mouseDelta:Float = MathUtil.distance(x, y, _lastClickX, _lastClickY);
			if (_lastClickTimeDiff < 0.5 && mouseDelta < 5) { // 0.5 seconds
				var type = haxe.ui.events.MouseEvent.DBL_CLICK;
				var fn:UIEvent->Void = _eventMap.get(type);
				if (fn != null) {
					var mouseEvent = new haxe.ui.events.MouseEvent(type);
					mouseEvent.screenX = x / Toolkit.scaleX;
					mouseEvent.screenY = y / Toolkit.scaleY;
					fn(mouseEvent);
				}
			}
        }
        _mouseDownFlag = false;
    }

    private function __onMouseWheel(event:MouseEvent) {
        var delta = event.delta;
        var fn = _eventMap.get(MouseEvent.MOUSE_WHEEL);

        if (fn == null) {
            return;
        }

        if (!inBounds(lastMouseX, lastMouseY)) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        mouseEvent.screenX = lastMouseX / Toolkit.scaleX;
        mouseEvent.screenY = lastMouseY / Toolkit.scaleY;
        mouseEvent.delta = Math.max(-1, Math.min(1, -delta));
        fn(mouseEvent);
    }
    
    //***********************************************************************************************************
    // Helpers
    //***********************************************************************************************************
    private var _interactive:Interactive = null;
    private var interactive(get, set):Bool;
    private function get_interactive():Bool {
        return (_interactive != null);
    }
    private function set_interactive(value:Bool):Bool {
        if (value == false) {
            _interactive = null;
        } else {
            if (_interactive == null) {
                _interactive = new Interactive(width, height, this);
                _interactive.propagateEvents = true;
                _interactive.enableRightButton = true;
                _interactive.x = 0;
                _interactive.y = 0;
            }
        }
        return value;
    }
}

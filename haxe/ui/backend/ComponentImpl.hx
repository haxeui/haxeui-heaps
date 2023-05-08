package haxe.ui.backend;

import h2d.Mask;
import h2d.Object;
import h2d.RenderContext;
import haxe.ui.Toolkit;
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
import haxe.ui.validation.InvalidationFlags;

class ComponentImpl extends ComponentBase {
    public var styleable:Bool = true;
    
    private var _eventMap:Map<String, UIEvent->Void>;
    
    static inline var INDEX_OFFSET = 1; // offset everything because 0th-child is always the style graphics container

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
        addChild(new Object()); // style graphics container
        //cast(this, Component).ready();
    }

    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left == null || top == null) {
            return;
        }
        
        left = Std.int(left);
        top = Std.int(top);

        if (_mask == null) {
            if (this.x != left) this.x = left;
            if (this.y != top)  this.y = top;
        } else {
            if (_mask.x != left) _mask.x = left;
            if (_mask.y != top)  _mask.y = top;
        }
    }
    
    private override function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        if (this.styleable) {
            StyleHelper.apply(this, style, w, h);
        }
    }
    
    private override function handleVisibility(show:Bool) {
        super.visible = show;
    }
    
    private var _mask:Mask = null;
    private override function handleClipRect(value:Rectangle) {
        if (value != null) {
            if (_mask == null) {
                _mask = new Mask(Std.int(value.width * Toolkit.scaleX), Std.int(value.height * Toolkit.scaleY), this.parentComponent);
                _mask.addChild(this);
            }
            value.toInts();
            this.x = -value.left;
            this.y = -value.top;
            _mask.x = left;
            _mask.y = top;
            _mask.width = Std.int(value.width);
            _mask.height = Std.int(value.height);
            
            var hasFilter = hasFilter();
            if (hasFilter) {
                this.x += 1;
                this.y -= 4;
                _mask.y += 4;
                _mask.width += 3;
            }
        } else if (_mask != null) {
            _mask = null;
        }
    }
    
    /*
     * This is a hack for now, since filters and masks dont play well together, investigate mask filters:
            var myMaskedElementsContainer = new Object();
            var mask = new Graphics();
            mask.beginFill(0xFF0000, 1.0);
            mask.drawRect(0, 0, maskWidth, maskHeight);
            parent.addChild(mask); // Must be added before masked content
            parent.addChild(myMaskedElementsContainer);
            myMaskedElementsContainer.filter = new Mask(mask); // h2d.filter.Mask
     */
    private function hasFilter() {
        var p = this;
        while (p != null) {
            if (p.style.filter != null) {
                return true;
            }
            p = p.parentComponent;
        }
        return false;
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
    private override function handleReady() {
        super.handleReady();
        @:privateAccess Screen.instance.addUpdateCallback();
    }
    
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
    
    private var _deallocate:Bool = false;
    private var deallocate(null, set):Bool;
    private function set_deallocate(value:Bool) {
        _deallocate = value;
        for (c in this.childComponents) {
            c.deallocate = value;
        }
        return value;
    }
    private var _disposed:Bool = false;
    private function dispose() {
        if (_disposed == true) {
            return;
        }
        deallocate = true;
        removeChildren();
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
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_MOVE, listener);
                }
                
            case MouseEvent.MOUSE_OVER:
                if (_eventMap.exists(MouseEvent.MOUSE_OVER) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_OVER, listener);
                }
                
            case MouseEvent.MOUSE_OUT:
                if (_eventMap.exists(MouseEvent.MOUSE_OUT) == false) {
                    _eventMap.set(MouseEvent.MOUSE_OUT, listener);
                }
                
            case MouseEvent.MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                }
                
            case MouseEvent.MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_UP, listener);
                }
                
            case MouseEvent.MOUSE_WHEEL:
                if (_eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    MouseHelper.notify(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                    _eventMap.set(MouseEvent.MOUSE_WHEEL, listener);
                }
                
            case MouseEvent.CLICK:
                if (_eventMap.exists(MouseEvent.CLICK) == false) {
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
                    _eventMap.set(MouseEvent.DBL_CLICK, listener);
                    
                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onDoubleClick);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
                
            case MouseEvent.RIGHT_MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                }
                
            case MouseEvent.RIGHT_CLICK:
                if (_eventMap.exists(MouseEvent.RIGHT_CLICK) == false) {
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

            case MouseEvent.MIDDLE_MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MIDDLE_MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MIDDLE_MOUSE_DOWN, listener);
                }

            case MouseEvent.MIDDLE_MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MIDDLE_MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MIDDLE_MOUSE_UP, listener);
                }
                
            case MouseEvent.MIDDLE_CLICK:
                if (_eventMap.exists(MouseEvent.MIDDLE_CLICK) == false) {
                    _eventMap.set(MouseEvent.MIDDLE_CLICK, listener);

                    if (_eventMap.exists(MouseEvent.MIDDLE_MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MIDDLE_MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.MIDDLE_MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MIDDLE_MOUSE_UP, listener);
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
                
            case MouseEvent.MIDDLE_MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.MIDDLE_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.MIDDLE_MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.MIDDLE_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
                
            case MouseEvent.MIDDLE_CLICK:
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
        var last:Component = null;
        var xpos:Float = 0;
        var ypos:Float = 0;
        while (c != null) {
            xpos += c.left;
            ypos += c.top;
            if (c.componentClipRect != null) {
                xpos -= c.componentClipRect.left;
                ypos -= c.componentClipRect.top;
            }
            last = c;
            c = c.parentComponent;
        }
        
        if (last != null && last.parent != null) { // UI might have been added deep in a heaps hierachy, so lets get the _real_ screen pos
            var o = last.parent;
            while (o != null) {
                xpos += o.x;
                ypos += o.y;
                o = o.parent;
            }
        }
        
        xpos *= Toolkit.scaleX;
        ypos *= Toolkit.scaleY;

        xpos += last.left * (1-Toolkit.scaleX);
        ypos += last.top * (1-Toolkit.scaleY);

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

        if (isOnScreen() == false) {
            return false;
        }

        x *= Toolkit.scaleX;
        y *= Toolkit.scaleY;
        var b:Bool = false;
        var sx = screenX;
        var sy = screenY;
        var cx = this.width * Toolkit.scaleX;
        var cy = this.height * Toolkit.scaleY;

        if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
            b = true;
        }

        // let make sure its in the clip rect too
        if (b == true) {
            var clip:Component = findClipComponent();
            if (clip != null) {
                b = false;
                var sx = (clip.screenX + (clip.componentClipRect.left * Toolkit.scaleX));
                var sy = (clip.screenY + (clip.componentClipRect.top * Toolkit.scaleY));
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
        var changed = posChanged;
        // if .x/.y property is access directly, we still want to honour it, so we will set haxeui's
        // .left/.top to keep them on sync, but only if the components position isnt already invalid
        // (which would mean this has come from a haxeui validation cycle)
        if (changed == true && isComponentInvalid(InvalidationFlags.POSITION) == false && _mask == null) {
            if (this.x != this.left) {
                this.left = this.x;
            }
            if (this.y != this.top) {
                this.top = this.y;
            }
        }
        super.sync(ctx);
        clearCaches();
    }
    
    private  override function onAdd() {
        super.onAdd();
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) == -1) {
            Screen.instance.addComponent(cast this);
        }
        cast(this, Component).ready();
    }
    
    private override function onRemove() {
        if (_deallocate == true) {
            _disposed = true;
            super.onRemove();
        }
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) != -1) {
            Screen.instance.removeComponent(cast this, _deallocate);
        }
    }
    
    private var lastMouseX:Float = -1;
    private var lastMouseY:Float = -1;
    
    // For doubleclick detection
    private var _lastClickTime:Float = 0;
    private var _lastClickTimeDiff:Float = MathUtil.MAX_INT;
    private var _lastClickX:Float = -1;
    private var _lastClickY:Float = -1;
    
    private function calcCursor():String {
        var c = null;
        var p = this;
        while (p != null) {
            if (p.style != null && p.style.cursor != null) {
                c = p.style.cursor;
                break;
            }
            p = p.parentComponent;
        }
        return c;
    }
    
    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(event:MouseEvent) {
        var x = event.screenX;
        var y = event.screenY;
        lastMouseX = x;
        lastMouseY = y;

        var i = inBounds(x, y);
        if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            Screen.instance.setCursor("default");
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
                event.canceled = mouseEvent.canceled;
            }
            return;
        }
        
        if (i == true) {
            if (isEventRelevant(getComponentsAtPoint(x, y, true), MouseEvent.MOUSE_OVER)) {
                if (isInteractiveAbove(x, y)) {
                    return;
                }
            }

            if (this.style != null) {
                Screen.instance.setCursor(calcCursor());
            }
            
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_MOVE);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_MOVE);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
                event.canceled = mouseEvent.canceled;
            }
        }
        
        if (i == true && _mouseOverFlag == false) {
            if (isEventRelevant(getComponentsAtPoint(x, y, true), MouseEvent.MOUSE_OVER)) {
                _mouseOverFlag = true;
                var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OVER);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OVER);
                    mouseEvent.screenX = x;
                    mouseEvent.screenY = y;
                    fn(mouseEvent);
                    event.canceled = mouseEvent.canceled;
                }
            }
        } else if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            Screen.instance.setCursor("default");
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
                event.canceled = mouseEvent.canceled;
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
                if (isInteractiveAbove(x, y)) {
                    return;
                }

                _mouseDownFlag = true;
                
                if (this.style != null && (this.style.cursor == "row-resize" || this.style.cursor == "col-resize")) {
                    Screen.instance.lockCursor();
                }
                
                _mouseDownButton = button;
                var type = switch(button) {
                    case 0: haxe.ui.events.MouseEvent.MOUSE_DOWN;
                    case 1: haxe.ui.events.MouseEvent.RIGHT_MOUSE_DOWN;
                    case 2: haxe.ui.events.MouseEvent.MIDDLE_MOUSE_DOWN;
                    case _: haxe.ui.events.MouseEvent.MOUSE_DOWN;
                }
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.data = button;
                    mouseEvent.screenX = x;
                    mouseEvent.screenY = y;
                    fn(mouseEvent);
                    event.canceled = mouseEvent.canceled;
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
                var type = switch(button) {
                    case 0: haxe.ui.events.MouseEvent.CLICK;
                    case 1: haxe.ui.events.MouseEvent.RIGHT_CLICK;
                    case 2: haxe.ui.events.MouseEvent.MIDDLE_CLICK;
                    case _: haxe.ui.events.MouseEvent.CLICK;
                }
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.data = button;
                    mouseEvent.screenX = x;
                    mouseEvent.screenY = y;
                    Toolkit.callLater(function() {
                        fn(mouseEvent);
                        event.canceled = mouseEvent.canceled;
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

            if (_mouseDownFlag && this.style != null) {
                Screen.instance.unlockCursor();
                Screen.instance.setCursor(calcCursor());
            }
            
            _mouseDownFlag = false;
            var type = switch(button) {
                case 0: haxe.ui.events.MouseEvent.MOUSE_UP;
                case 1: haxe.ui.events.MouseEvent.RIGHT_MOUSE_UP;
                case 2: haxe.ui.events.MouseEvent.MIDDLE_MOUSE_UP;
                case _: haxe.ui.events.MouseEvent.MOUSE_UP;
            }
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.data = button;
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
                event.canceled = mouseEvent.canceled;
            }
        } else {
            if (_mouseDownFlag) {
                Screen.instance.unlockCursor();
                Screen.instance.setCursor("default");
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
                    mouseEvent.data = button;
                    mouseEvent.screenX = x;
                    mouseEvent.screenY = y;
                    fn(mouseEvent);
                    event.canceled = mouseEvent.canceled;
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

        if (isInteractiveAbove(lastMouseX, lastMouseY)) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        mouseEvent.screenX = lastMouseX;
        mouseEvent.screenY = lastMouseY;
        mouseEvent.delta = Math.max(-1, Math.min(1, -delta));
        fn(mouseEvent);
        event.canceled = mouseEvent.canceled;
    }

    //***********************************************************************************************************
    // Helpers
    //***********************************************************************************************************
    private override function set_visible(value:Bool):Bool {
        if (value == this.visible) {
            return value;
        }
        super.visible = value;
        cast(this, Component).hidden = !value;
        return value;
    }

    private function calcObjectIndex(obj:Object):Int {
        var n = 0;
        while (obj.parent != null) {
            n++;
            if (obj.parent == obj.getScene()) {
                break;
            }
            obj = obj.parent;
        }
        return obj.getScene().getChildIndex(obj);
    }

    private function isOnScreen() {
        var obj:Object = this;
        while (obj.parent != null) {
            if (obj.visible == false) {
                return false;
            }
            obj = obj.parent;
            if (obj == obj.getScene()) {
                break;
            }
        }
        return true;
    }

    private function isInteractiveAbove(x:Float, y:Float) {
        var scene = this.getScene();
        if (scene != null) {
            var interactive = scene.getInteractive(x, y);
            if (interactive != null) {
                var n1 = calcObjectIndex(interactive);
                var n2 = calcObjectIndex(this);
                if (n1 > n2) {
                    hxd.System.setNativeCursor(interactive.cursor);
                    return true;
                }
            }
        }

        return false;
    }
}

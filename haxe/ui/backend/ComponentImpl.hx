package haxe.ui.backend;

import h2d.Camera;
import h2d.Graphics;
import h2d.Object;
import h2d.RenderContext;
import h2d.Scene;
import h2d.col.Point;
import h2d.filter.Filter;
import h2d.filter.Group;
import h2d.filter.Mask;
import haxe.ui.Toolkit;
import haxe.ui.backend.heaps.FilterConverter;
import haxe.ui.backend.heaps.MouseHelper;
import haxe.ui.backend.heaps.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.Screen;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import haxe.ui.util.MathUtil;
import haxe.ui.validation.InvalidationFlags;

class ComponentImpl extends ComponentBase {
    public var styleable:Bool = true;
    
    @:noCompletion
    private var _eventMap:Map<String, UIEvent->Void>;
    @:noCompletion
    private var _container:Object = null;
    
    @:noCompletion
    static inline var INDEX_OFFSET = 1; // offset everything because 0th-child is always the style graphics container

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
        _container = new Object();
        _container.name = "container";
        var styleGraphics = new Graphics();
        styleGraphics.name = "styleGraphics";
        _container.addChild(styleGraphics);
        addChild(_container); // style graphics container
        //cast(this, Component).ready();
    }

    @:noCompletion
    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left == null || top == null) {
            return;
        }

        left = Math.fround(left);
        top = Math.fround(top);

        if (this.x != left) this.x = left;
        if (this.y != top)  this.y = top;
    }
    
    @:noCompletion
    private override function handleSize(w:Null<Float>, h:Null<Float>, style:Style) {
        if (h == null || w == null || w <= 0 || h <= 0) {
            return;
        }

        if (this.styleable) {
            StyleHelper.apply(this, style, w, h);
        }
    }
    
    @:noCompletion
    private override function handleVisibility(show:Bool) {
        super.visible = show;
    }
    
    @:noCompletion
    private var _maskGraphics:Graphics = null;
    @:noCompletion
    private override function handleClipRect(value:Rectangle) {
        if (_maskGraphics == null) {
            _maskGraphics = new Graphics();
            _maskGraphics.name = "maskGraphics";

            _container.addChildAt(_maskGraphics, 0);
            _maskFilter = new Mask(_maskGraphics);
            this.filter = createFilterGroup();
        }

        var borderSize:Float = 0;
        if (parentComponent != null && parentComponent.style == null) {
            parentComponent.validateNow();
        }
        borderSize = parentComponent.style.borderSize;

        _maskGraphics.clear();
        _maskGraphics.beginFill(0xFF00FF, 1.0);
        _maskGraphics.drawRect(0, 0, value.width, value.height);
        _maskGraphics.endFill();
        _maskGraphics.x = value.left;//this.left;
        _maskGraphics.y = value.top;//this.top;

        // is this a hack? We dont want to move the component if the clip rect is the 
        // full size of the component (like in the case of clip:true), feels wrong
        // for some reason, but without this, clip:true components move around
        // when they shouldnt (which i dont fully understand)
        if (this.width != value.width) {
            // multiple masks / clip rects in the same component (like tableview) can interfere with each
            // other in heaps, so lets find them and update our co-ords appropriately
            var offsetX:Float = 0;
            for (c in this.parentComponent.childComponents) {
                if (c._maskGraphics != null && c._maskGraphics != this._maskGraphics) {
                    var clipComponent = c.findClipComponent();
                    if (clipComponent != null && clipComponent.width != this.width) {
                        trace(clipComponent.width, this.width);
                        offsetX += clipComponent.width;
                    }
                }
            }
            this.x = -value.left + borderSize + offsetX;
        }
        if (this.height != value.height) {
            // multiple masks / clip rects in the same component (like tableview) can interfere with each
            // other in heaps, so lets find them and update our co-ords appropriately
            var offsetY:Float = 0;
            for (c in this.parentComponent.childComponents) {
                if (c._maskGraphics != null && c._maskGraphics != this._maskGraphics) {
                    var clipComponent = c.findClipComponent();
                    if (clipComponent != null && clipComponent.height != this.height) {
                        offsetY += clipComponent.height;
                    }
                }
            }
            this.y = -value.top + borderSize + offsetY;
        }
    }

    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    @:noCompletion
    public override function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            super.createTextDisplay(text);
            addChild(_textDisplay.sprite);
        }
        
        return _textDisplay;
    }

    @:noCompletion
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
    @:noCompletion
    public override function createImageDisplay():ImageDisplay {
        if (_imageDisplay == null) {
            super.createImageDisplay();
            addChild(_imageDisplay.sprite);
        }
        
        return _imageDisplay;
    }
    
    @:noCompletion
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
    @:noCompletion
    private override function handleReady() {
        super.handleReady();
        @:privateAccess Screen.instance.addUpdateCallback();
    }
    
    @:noCompletion
    private override function handleSetComponentIndex(child:Component, index:Int) {
        addChildAt(child, index + INDEX_OFFSET);
    }

    @:noCompletion
    private override function handleAddComponent(child:Component):Component {
        addChild(child);
        return child;
    }

    @:noCompletion
    private override function handleAddComponentAt(child:Component, index:Int):Component {
        addChildAt(child, index + INDEX_OFFSET);
        return child;
    }

    @:noCompletion
    private override function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        removeChild(child);
        
        if (dispose == true) {
            child.dispose();
        }
        
        return child;
    }

    @:noCompletion
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
    
    @:noCompletion
    private var _deallocate:Bool = false;
    @:noCompletion
    private var deallocate(null, set):Bool;
    @:noCompletion
    private function set_deallocate(value:Bool) {
        _deallocate = value;
        for (c in this.childComponents) {
            c.deallocate = value;
        }
        return value;
    }

    @:noCompletion
    private var _disposed:Bool = false;
    @:noCompletion
    private function dispose() {
        if (_disposed == true) {
            return;
        }
        deallocate = true;
        removeChildren();
        _maskGraphics = null;
        remove();
    }

    @:noCompletion
    private var _currentStyleFilters:Array<Filter> = null;
    @:noCompletion
    private var _maskFilter:Mask = null;
    @:noCompletion
    private function createFilterGroup() {
        var n = 0;
        var filterGroup = new Group();
        if (_maskFilter != null) {
            filterGroup.add(_maskFilter);
            n++;
        }
        if (_currentStyleFilters != null) {
            for (f in _currentStyleFilters) {
                filterGroup.add(f);
                n++;
            }
        }
        if (n == 0) {
            return null;
        }
        return filterGroup;
    }

    @:noCompletion
    private override function applyStyle(style:Style) {
        /*
        if (style.cursor != null && style.cursor == "pointer") {
            cursor = Cursor.Button;
        } else if (cursor != hxd.Cursor.Default) {
            cursor = Cursor.Default;
        }
        */
        if (style.filter != null && style.filter.length > 0) {
            _currentStyleFilters = [];
            for (f in style.filter) {
                var filter = FilterConverter.convertFilter(f);
                if (filter != null) {
                    _currentStyleFilters.push(filter);
                }
            }
            this.filter = createFilterGroup();
        } else {
            _currentStyleFilters = null;
            this.filter = createFilterGroup();
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
    @:noCompletion
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

            case KeyboardEvent.KEY_DOWN:
                if (hasTextInput() && !_eventMap.exists(KeyboardEvent.KEY_DOWN)) {
                    _eventMap.set(KeyboardEvent.KEY_DOWN, listener);
                    getTextInput().onKeyDown = listener;
                }

            case KeyboardEvent.KEY_UP:
                if (hasTextInput() && !_eventMap.exists(KeyboardEvent.KEY_UP)) {
                    _eventMap.set(KeyboardEvent.KEY_UP, listener);
                    getTextInput().onKeyUp = listener;
                }

            case KeyboardEvent.KEY_PRESS:
                if (hasTextInput() && !_eventMap.exists(KeyboardEvent.KEY_PRESS)) {
                    _eventMap.set(KeyboardEvent.KEY_PRESS, listener);
                    getTextInput().onKeyPress = listener;
                }
        }
    }

    @:noCompletion
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
    @:noCompletion
    private var _cachedScreenX:Null<Float> = null;
    @:noCompletion
    private var _cachedScreenY:Null<Float> = null;
    @:noCompletion
    private var _cachedClipComponent:Component = null;
    @:noCompletion
    private var _cachedClipComponentNone:Null<Bool> = null;
    @:noCompletion
    private var _cachedRootComponent:Component = null;
    
    @:noCompletion
    private function clearCaches() {
        _cachedScreenX = null;
        _cachedScreenY = null;
        _cachedClipComponent = null;
        _cachedClipComponentNone = null;
        _cachedRootComponent = null;
    }
    
    @:noCompletion
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
    
    @:noCompletion
    private var screenX(get, null):Float;
    @:noCompletion
    private function get_screenX():Float {
        cacheScreenPos();
        return _cachedScreenX;
    }

    @:noCompletion
    private var screenY(get, null):Float;
    @:noCompletion
    private function get_screenY():Float {
        cacheScreenPos();
        return _cachedScreenY;
    }

    @:noCompletion
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
    
    @:noCompletion
    private function isRootComponent():Bool {
        return (findRootComponent() == this);
    }
    
    @:noCompletion
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
    
    @:noCompletion
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
    
    @:noCompletion
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

    @:noCompletion
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

    @:noCompletion
    private function findChildrenAtPoint(child:Component, x:Float, y:Float, array:Array<Component>) {
        if (child.inBounds(x, y) == true) {
            array.push(child);
        }
        for (c in child.childComponents) {
            findChildrenAtPoint(c, x, y, array);
        }
    }

    @:noCompletion
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
    
    @:noCompletion
    private override function sync(ctx:RenderContext) {
        var changed = posChanged;
        // if .x/.y property is access directly, we still want to honour it, so we will set haxeui's
        // .left/.top to keep them on sync, but only if the components position isnt already invalid
        // (which would mean this has come from a haxeui validation cycle)
        if (changed == true && isComponentInvalid(InvalidationFlags.POSITION) == false && _maskGraphics == null) {
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
    
    @:noCompletion
    private override function onAdd() {
        super.onAdd();
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) == -1) {
            Screen.instance.addComponent(cast this);
        }
        cast(this, Component).ready();
    }
    
    @:noCompletion
    private override function onRemove() {
        if (_deallocate == true) {
            _disposed = true;
            super.onRemove();
        }
        if (this.parentComponent == null && Screen.instance.rootComponents.indexOf(cast this) != -1) {
            Screen.instance.removeComponent(cast this, _deallocate);
        }
    }
    
    @:noCompletion
    private var lastMouseX:Float = -1;
    @:noCompletion
    private var lastMouseY:Float = -1;
    
    // For doubleclick detection
    @:noCompletion
    private var _lastClickTime:Float = 0;
    @:noCompletion
    private var _lastClickTimeDiff:Float = MathUtil.MAX_INT;
    @:noCompletion
    private var _lastClickX:Float = -1;
    @:noCompletion
    private var _lastClickY:Float = -1;
    
    @:noCompletion
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
    
    @:noCompletion
    private function findScene():Scene {
        if (this.getScene() != null) {
            return this.getScene();
        }
        return Screen.instance.scene;
    }

    @:noCompletion
    private function findCamera():Camera {
        var scene = findScene();
        if (scene == null) {
            return null;
        }

        if (scene.interactiveCamera != null) {
            return scene.interactiveCamera;
        }
        return scene.camera;
    }

    @:noCompletion
    private var _h2dPoint = new Point(); // we'll just reuse the same point rather than creating new ones
    @:noCompletion
    private function eventToCamera(event:MouseEvent) {
        _h2dPoint.x = event.screenX;
        _h2dPoint.y = event.screenY;
        var camera = findCamera();
        if (camera != null) {
            camera.screenToCamera(_h2dPoint);
        }
        event.screenX = _h2dPoint.x / Toolkit.scaleX;
        event.screenY = _h2dPoint.y / Toolkit.scaleY;
    }

    @:noCompletion
    private var _mouseOverFlag:Bool = false;
    @:noCompletion
    private function __onMouseMove(event:MouseEvent) {
        eventToCamera(event);

        var x = event.screenX;
        var y = event.screenY;
        lastMouseX = x;
        lastMouseY = y;

        var i = inBounds(x, y);
        if (i == true) {
            if (_mouseOverFlag && hasComponentOver(cast this, x, y) == true) {
                _mouseOverFlag = false;
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

            if (isEventRelevant(getComponentsAtPoint(x, y, true), MouseEvent.MOUSE_OVER)) {
                if (isInteractiveAbove(x, y)) {
                    return;
                }

                var cursor = calcCursor();
                if (cursor != null) {
                    Screen.instance.setCursor(cursor);
                }
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
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }

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
    
    @:noCompletion
    private var _mouseDownFlag:Bool = false;
    @:noCompletion
    private var _mouseDownButton:Int = -1;
    @:noCompletion
    private function __onMouseDown(event:MouseEvent) {
        eventToCamera(event);

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
                
                /* TODO: feels hacky (ill-conceived?)
                if (this.style != null && (this.style.cursor == "row-resize" || this.style.cursor == "col-resize")) {
                    Screen.instance.lockCursor();
                }
                */
                
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

    @:noCompletion
    private function __onMouseUp(event:MouseEvent) {
        eventToCamera(event);

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

            /* TODO: feels hacky (ill-conceived?)
            if (_mouseDownFlag && this.style != null) {
                Screen.instance.unlockCursor();
                Screen.instance.setCursor(calcCursor());
            }
            */
            
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
            /* TODO: feels hacky (ill-conceived?)
            if (_mouseDownFlag) {
                Screen.instance.unlockCursor();
                Screen.instance.setCursor("default");
            }
            */
        }
        _mouseDownFlag = false;
    }
    
    @:noCompletion
    private function __onDoubleClick(event:MouseEvent) {
        eventToCamera(event);

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

    @:noCompletion
    private function __onMouseWheel(event:MouseEvent) {
        eventToCamera(event);

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
    @:noCompletion
    private function hasComponentOver(ref:Component, x:Float, y:Float):Bool {
        var array:Array<Component> = getComponentsAtPoint(x, y);
        if (array.length == 0) {
            return false;
        }

        return !hasChildRecursive(cast ref, cast array[array.length - 1]);
    }

    @:noCompletion
    private override function set_visible(value:Bool):Bool {
        if (value == this.visible) {
            return value;
        }
        super.visible = value;
        cast(this, Component).hidden = !value;
        return value;
    }

    @:noCompletion
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

    @:noCompletion
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

    @:noCompletion
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

![build status](https://github.com/haxeui/haxeui-heaps/actions/workflows/build.yml/badge.svg)

# haxeui-heaps
`haxeui-heaps` is the `Heaps` backend for `HaxeUI`.

## Installation
`haxeui-heaps` relies on `haxeui-core` as well as `Heaps`. To install:

```
haxelib install heaps
haxelib install haxeui-core
haxelib install haxeui-heaps
```

### Toolkit initialization and usage
Before you start using `HaxeUI` in your project, you must first initialize the `Toolkit`.

```haxe
Toolkit.init();
```

Once the toolkit is initialized, you can add components using the methods specified <a href="https://github.com/haxeui/haxeui-core#adding-components-using-haxe-code">here</a>.

```haxe
var app = new HaxeUIApp();
app.ready(
	function() {
		var main = ComponentMacros.buildComponent("assets/xml/test.xml"); // whatever your XML layout path is
		app.addComponent(main);
		app.start();
	}
);
```

Some examples are [here](https://github.com/haxeui/component-examples).

## Addtional resources
* <a href="http://haxeui.org/explorer/">component-explorer</a> - Browse HaxeUI components
* <a href="http://haxeui.org/builder/">playground</a> - Write and test HaxeUI layouts in your browser
* <a href="https://github.com/haxeui/component-examples">component-examples</a> - Various componet examples
* <a href="http://haxeui.org/api/haxe/ui/">haxeui-api</a> - The HaxeUI api docs.
* <a href="https://github.com/haxeui/haxeui-guides">haxeui-guides</a> - Set of guides to working with HaxeUI and backends.

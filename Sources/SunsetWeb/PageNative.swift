/// What each of Sunset's page-world scripts starts with: `native(body, name, length)` makes a function of Sunset's read as
/// WebKit's own — `[native code]` to `Function.prototype.toString`, its name and length as WebKit's, no `prototype`, not a
/// constructor; `nativeMark` does the same for a function made otherwise (a constructor). Each script wraps the `toString`
/// it finds, so they chain (the agent script, added last, outermost); nothing is left on a global.
enum PageNative {
    static let prelude = """
        const [native, nativeMark] = (() => {
          const texts = new WeakMap();
          const define = Object.defineProperty;
          const found = Function.prototype.toString;
          // An accessor is named "get title" and written "function title()", as WebKit writes it.
          const mark = (made, name, length) => {
            define(made, "name", { value: name });
            define(made, "length", { value: length });
            texts.set(made, "function " + name.replace(/^[gs]et /, "") + "() {\\n    [native code]\\n}");
            return made;
          };
          const toString = mark({ toString() {
            const own = texts.get(this);
            return own !== undefined ? own : Reflect.apply(found, this, []);
          } }.toString, "toString", 0);
          define(Function.prototype, "toString", { value: toString, writable: true, enumerable: false, configurable: true });
          // A method has no prototype and cannot be constructed, as WebKit's own operations and accessors.
          const native = (body, name, length = 0) => {
            const made = { [name](...args) { return Reflect.apply(body, this, args); } }[name];
            return mark(made, name, length);
          };
          return [native, mark];
        })();
        """
}

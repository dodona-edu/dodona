import { State } from "./State";

/**
 * Function for decorating a property that is compatible with both TypeScript decorators.
 * It will keep track of readers and dispatch events when the property is changed.
 *
 * @returns {void}
 */
export const stateProperty = (proto: State, name?: PropertyKey): void => {
    const key = typeof name === "symbol" ? Symbol() : `__${name}`;
    const currentVal = proto[name];
    Object.defineProperty(proto, name, {
        get(): unknown {
            this.recordRead(name);
            return this[key];
        },
        set(value: unknown) {
            this[key] = value;
            this.dispatchStateEvent(name);
        },
        configurable: true,
        enumerable: true,
    });
    proto[key] = currentVal;
};

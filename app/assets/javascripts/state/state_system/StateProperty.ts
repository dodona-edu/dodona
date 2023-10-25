import { State } from "./State";

/**
 * Function for decorating a property that is compatible with both TypeScript and Babel decorators.
 * It will apply the `finisher` function to the property.
 *
 * @returns {void}
 */
export const stateProperty = (
    proto: State ,
    name?: PropertyKey
): void  => {
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
        writable: true,
        configurable: true,
        enumerable: true,
    });
    proto[key] = currentVal;
};

import { State } from "./State";
import { ClassElement, Constructor } from "@lit/reactive-element/decorators/base.js";

/**
 * This function is used to decorate a property of a State class.
 * It will make the property reactive and will dispatch a StateEvent when the property changes.
 * It will also record every read of the property to the stateRecorder.
 * @param stateClass
 * @param property
 */
function finisher(stateClass: typeof State, property: PropertyKey): void {
    const key = typeof property === "symbol" ? Symbol() : `__${property}`;
    const currentVal = stateClass.prototype[property];
    Object.defineProperty(stateClass.prototype, property, {
        get(): unknown {
            this.recordRead(property);
            return this[key];
        },
        set(value: unknown) {
            this[key] = value;
            this.dispatchStateEvent(property);
        },
        configurable: true,
        enumerable: true,
    });
    stateClass.prototype[key] = currentVal;
}

/**
 * Function for decorating a property that is compatible with both TypeScript and Babel decorators.
 * It will apply the `finisher` function to the property.
 *
 * @returns {ClassElement|void}
 */
export const stateProperty = (
    protoOrDescriptor: State | ClassElement,
    name?: PropertyKey
    // Note TypeScript requires the return type to be `void|any`
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
): void | any => {
    if (name !== undefined) {
        // TypeScript / Babel legacy mode
        const ctor = (protoOrDescriptor as State).constructor as typeof State;
        Object.defineProperty(protoOrDescriptor, name, {
            writable: true,
            configurable: true,
            enumerable: true
        });
        finisher(ctor, name);
    } else {
        // Babel standard mode
        const element = protoOrDescriptor as ClassElement;
        return {
            kind: "field",
            placement: "prototype",
            key: Symbol(),
            descriptor: {},
            finisher: function <State> (ctor: Constructor<State>) {
                finisher(ctor as typeof State, element.key);
            },
            initializer(this: {[key: symbol]: unknown}) {
                if (typeof element.initializer === "function") {
                    this[element.key] = element.initializer.call(this);
                }
            },
        };
    }
};

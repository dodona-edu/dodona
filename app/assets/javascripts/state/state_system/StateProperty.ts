import { State } from "./State";

// type FieldDescriptor = {
//     kind: "field" | "method" | "accessor",
//     key: string | symbol,
//     placement: "static" | "prototype" | "own",
//     initializer?: () => any,
//     finisher?: (c: any) => void,
// } & PropertyDescriptor;
// type FieldDecorator = (descriptor: FieldDescriptor) => FieldDescriptor;

/**
 * This function actually has the type of a FieldDecorator, but we need to
 * declare it to generally support any arguments and return any because typescript expects
 * (target: Object, propertyKey: string | symbol) => PropertyDescriptor
 */

/**
 * StateProperty is a decorator that can be used to define a property in a State class.
 * The property will record read events and dispatch state change events when changed.
 */
export const stateProperty: (...args: any[]) => any = descriptor => {
    return {
        kind: "field",
        key: Symbol(),
        placement: "own",
        descriptor: {},
        initializer() {
            if (typeof descriptor.initializer === "function") {
                this[descriptor.key] = descriptor.initializer.call(this);
            }
        },
        finisher(stateClass: typeof State) {
            const key = typeof descriptor.key === "symbol" ? Symbol() : `__${descriptor.key}`;
            Object.defineProperty(stateClass.prototype, descriptor.key, {
                get(): unknown {
                    this.recordRead(descriptor.key);
                    return this[key];
                },
                set(value: unknown) {
                    this[key] = value;
                    this.dispatchStateEvent(descriptor.key, value);
                },
                configurable: true,
                enumerable: true,
            });
        }
    };
};

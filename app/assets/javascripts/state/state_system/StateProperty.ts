import { State } from "state/state_system/State";

/**
 * This function is used to decorate a property of a State class.
 * It will make the property reactive and will dispatch a StateEvent when the property changes.
 * It will also record every read of the property to the stateRecorder.
 * follows the specification TC39, see https://github.com/tc39/proposal-decorators#new-class-elements
 */
export function stateProperty<T>(
    accessor: {
        get: () => T;
        set(value: T): void;
    },
    context: ClassAccessorDecoratorContext<State, T>
): ClassAccessorDecoratorResult<State, T> | void {
    if (context.kind !== "accessor") {
        throw new Error("stateProperty decorator can only be used on accessors");
    }
    return {
        get(): T {
            this.recordRead(String(context.name));
            return accessor.get.call(this);
        },
        set(value: T): void {
            accessor.set.call(this, value);
            this.dispatchStateEvent(String(context.name));
        }
        // do not overwrite the initializer
    };
}


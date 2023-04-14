import { StateEvent } from "./StateEvent";
import { stateRecorder } from "state/state_system/StateRecorder";

/**
 * Callback function - used as callback subscription to a state change
 */
export type Callback = (state: State, key?: string) => void

export type Unsubscribe = () => void;

/**
 * `State` a class that inherits from `EventTarget`.
 * It can be subscribed to and will dispatch an event to all subscribers when any of its properties change.
 * It also records every read of it's properties to the stateRecorder.
 * All credits to _@lit-app/state_ for the idea to use `EventTarget` to avoid reinventing an event system.
 *
 * This code was inspired on the code from the [@lit-app/state State](https://github.com/lit-apps/lit-app/blob/main/packages/state/src/state.ts)
 */
export class State extends EventTarget {
    /**
     * subscribe to state change event. The callback will be called anytime
     * a state property change if `nameOrNames` is undefined, or only for matching
     * property values specified by `nameOrNames`
     * @param callback the callback function to call
     * @param nameOrNames
     * @returns a unsubscribe function.
     */
    subscribe(callback: Callback, nameOrNames?: string | Set<string|undefined>): Unsubscribe {
        const names = nameOrNames instanceof Set ? nameOrNames : new Set([nameOrNames]);
        const cb: EventListener = (event: StateEvent) => {
            if (names.has(event.key) || !event.key || names.has(undefined)) {
                callback(this, event.key);
            }
        };
        this.addEventListener(StateEvent.eventName, cb);
        return () => this.removeEventListener(StateEvent.eventName, cb);
    }

    protected recordRead(key?: string): void {
        stateRecorder.recordRead(this, key);
    }

    protected dispatchStateEvent(key?: string): void {
        this.dispatchEvent(new StateEvent(this, key));
    }
}

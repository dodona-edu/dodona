import { StateEvent } from "./StateEvent";
import { stateRecorder } from "state/state_system/StateRecorder";

/**
 * Callback function - used as callback subscription to a state change
 */
export type Callback = (key: string, value: any, state: State) => void

export type Unsubscribe = () => void;

export class State extends EventTarget {
    /**
     * subscribe to state change event. The callback will be called anytime
     * a state property change if `nameOrNames` is undefined, or only for matching
     * property values specified by `nameOrNames`
     * @param callback the callback function to call
     * @param nameOrNames
     * @returns a unsubscribe function.
     */
    subscribe(callback: Callback, nameOrNames?: string | string[]): Unsubscribe {
        const names: string[] = (nameOrNames && !Array.isArray(nameOrNames)) ? [nameOrNames] : nameOrNames as string[];
        const cb: EventListener = (event: StateEvent) => {
            if (!names || names.includes(event.key)) {
                callback(event.key, event.value, this);
            }
        };
        this.addEventListener(StateEvent.eventName, cb);
        return () => this.removeEventListener(StateEvent.eventName, cb);
    }

    private recordRead(key: string): void {
        stateRecorder.recordRead(this, key);
    }

    private dispatchStateEvent(key: string, eventValue: unknown): void {
        this.dispatchEvent(new StateEvent(key, eventValue, this));
    }
}

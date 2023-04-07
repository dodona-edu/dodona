import { State } from "state/state_system/State";

/**
 * This event is fired to inform a state has updated one of its value
 *
 * This code is copied from the [@lit-app/state StateEvent](https://github.com/lit-apps/lit-app/blob/main/packages/state/src/state-event.ts)
 */
export class StateEvent extends Event {
    static readonly eventName = "lit-state-changed";
    readonly key: string | undefined;
    readonly state: State;

    /**
     * @param  {string} key of the state that has changed
     * @param  {unknown} value for the changed key
     * @param  {State} state the state that has changed
     */
    constructor(state: State, key?: string ) {
        super(StateEvent.eventName, { cancelable: false });
        this.key = key;
        this.state = state;
    }
}

declare global {
    interface HTMLElementEventMap {
        [StateEvent.eventName]: StateEvent;
    }
}

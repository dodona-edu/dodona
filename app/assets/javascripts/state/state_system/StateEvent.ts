import { State } from "state/state_system/State";

/**
 * This event is fired to inform a state has updated one of its value
 */
export class StateEvent extends Event {
    static readonly eventName = "lit-state-changed";
    readonly key: string;
    readonly state: State;

    readonly value: unknown;

    /**
     * @param  {string} key of the state that has changed
     * @param  {unknown} value for the changed key
     * @param  {State} state the state that has changed
     */
    constructor(key: string, value: unknown, state: State) {
        super(StateEvent.eventName, { cancelable: false });
        this.key = key;
        this.value = value;
        this.state = state;
    }
}

declare global {
    interface HTMLElementEventMap {
        [StateEvent.eventName]: StateEvent;
    }
}

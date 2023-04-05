import { State } from "./State";

/**
 * A global instance that records every property of a state that gets read between it's start and finish.
 * Credits to _litState_.
 *
 * Based on the code from the [litState StateRecorder](https://github.com/gitaarik/lit-state/blob/8cd66223612c3b115c0275f58f6cee5e900ee534/lit-state.js#L233)
 */
class StateRecorder {
    log: Map<State, string[]> = null;

    start(): void {
        this.log = new Map();
    }

    recordRead(stateObj: State, key?: string): void {
        if (this.log === null) return;
        const keys = this.log.get(stateObj) || [];
        if (!keys.includes(key)) keys.push(key);
        this.log.set(stateObj, keys);
    }

    finish(): Map<State, string[]> {
        const stateVars = this.log;
        this.log = null;
        return stateVars;
    }
}

export const stateRecorder = new StateRecorder();

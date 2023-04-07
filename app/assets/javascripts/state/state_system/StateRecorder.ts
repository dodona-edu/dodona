import { State } from "./State";

/**
 * A global instance that records every property of a state that gets read between it's start and finish.
 * Credits to _litState_.
 *
 * Based on the code from the [litState StateRecorder](https://github.com/gitaarik/lit-state/blob/8cd66223612c3b115c0275f58f6cee5e900ee534/lit-state.js#L233)
 */
class StateRecorder {
    private started = false;
    private log: Map<State, Set<string|undefined>> = new Map();

    start(): void {
        this.log = new Map();
        this.started = true;
    }

    recordRead(stateObj: State, key?: string): void {
        if (!this.started) {
            return;
        }
        if (!this.log.has(stateObj)) {
            this.log.set(stateObj, new Set());
        }

        const keys = this.log.get(stateObj);
        if (!keys.has(key)) {
            keys.add(key);
        }
    }

    finish(): Map<State, Set<string|undefined>> {
        if (!this.started) {
            throw new Error("StateRecorder is not started");
        }

        this.started = false;
        return this.log;
    }
}

export const stateRecorder = new StateRecorder();

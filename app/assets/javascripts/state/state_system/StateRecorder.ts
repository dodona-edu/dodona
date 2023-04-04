import { State } from "./State";

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

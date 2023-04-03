import { ReactiveController, ReactiveControllerHost } from "lit";
import { stateRecorder } from "state/state_system/StateRecorder";
import { State, Unsubscribe } from "state/state_system/State";

export class StateController implements ReactiveController {
    unsubscribeList: Unsubscribe[] = [];
    wasConnected = false;
    isConnected = false;

    constructor( protected host: ReactiveControllerHost) {
        this.host.addController(this);
    }

    hostConnected(): void {
        this.isConnected = true;
        if (this.wasConnected) {
            this.host.requestUpdate();
            this.wasConnected = false;
        }
    }
    hostDisconnected(): void {
        this.isConnected = false;
        this.wasConnected = true;
        this.clearStateObservers();
    }

    hostUpdate(): void {
        stateRecorder.start();
    }

    hostUpdated(): void {
        this.initStateObservers();
    }

    private initStateObservers(): void {
        this.clearStateObservers();
        if (!this.isConnected) return;
        this.addStateObservers(stateRecorder.finish());
    }

    private addStateObservers(stateVars: Map<State, string[]>): void {
        for (const [state, keys] of stateVars) {
            const unsubscribe = state.subscribe(() => this.host.requestUpdate(), keys);
            this.unsubscribeList.push(unsubscribe);
        }
    }

    private clearStateObservers(): void {
        this.unsubscribeList.forEach(unsubscribe => unsubscribe());
        this.unsubscribeList = [];
    }
}

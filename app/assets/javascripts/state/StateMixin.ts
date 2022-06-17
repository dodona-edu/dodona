import { LitElement } from "lit";
import { events } from "state/PubSub";

type Constructor = new (...args: any[]) => LitElement;

export function stateMixin<T extends Constructor>(superClass: T): T {
    class StateMixinClass extends superClass {
        state: string[];
        connectedCallback(): void {
            super.connectedCallback();
            this.initReactiveState();
        }

        private initReactiveState(): void {
            this.state = this.state || [];
            this.state.forEach( event => events.subscribe(event, () => this.requestUpdate()));
        }
    }

    // Cast return type to the superClass type passed in
    return StateMixinClass as T;
}

import { LitElement } from "lit";
import { events } from "state/PubSub";

type Constructor = abstract new (...args: any[]) => LitElement;

export function stateMixin<T extends Constructor>(superClass: T): T {
    /**
     * This mixin makes a LitElement responsive to global state changes using the PubSub scheme
     *
     * @prop {string[]} state should contain a list of state events which should trigger a rerender of the component
     */
    abstract class StateMixinClass extends superClass {
        abstract get state(): string[];
        connectedCallback(): void {
            super.connectedCallback();
            this.initReactiveState();
        }

        private initReactiveState(): void {
            this.state.forEach( event => events.subscribe(event, () => this.requestUpdate()));
        }
    }

    // Cast return type to the superClass type passed in
    return StateMixinClass as T;
}

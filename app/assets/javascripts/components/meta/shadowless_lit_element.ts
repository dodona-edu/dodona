import { LitElement } from "lit";
export class ShadowlessLitElement extends LitElement {
    createRenderRoot(): Element | ShadowRoot {
        return this;
    }
}

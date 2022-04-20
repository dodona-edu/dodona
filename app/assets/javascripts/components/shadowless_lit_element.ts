import { LitElement } from "lit";

export class ShadowlessLitElement extends LitElement {
    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }
}

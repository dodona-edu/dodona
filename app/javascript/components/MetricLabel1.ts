import { html, css, LitElement } from "lit";
import { customElement, property } from "lit/decorators.js";

@customElement("metric-label")
export class MetricLabel1 extends LitElement {
    static styles = css`p { color: blue }`;

    @property({ type: Number })
    number: number;

    @property()
    label = "Somebody";

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    render(): unknown {
        return html`
          <h1>${this.number}</h1>
          ${this.label}`;
    }
}

import { html, css, LitElement } from "lit";
import { customElement, property } from "lit/decorators.js";

@customElement("metric-label-2")
export class MetricLabel2 extends LitElement {
    static styles = css`
        h1 {
            font-size: 36px;
            font-weight: 300;
            line-height: 48px;
            letter-spacing: -0.36px;
            margin: 0;
            white-space: nowrap;
        }
    `;

    @property({ type: Number })
    number: number;

    @property()
    label = "Somebody";

    render(): unknown {
        return html`
          <h1>${this.number}</h1>
          ${this.label}`;
    }
}

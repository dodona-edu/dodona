import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

@customElement("dodona-histogram")
export class Histogram extends LitElement {
    @property({ type: Array })
    values: number[];

    static styles = css`
        :host {
            display: flex;
            align-items: flex-end;
            height: 100%;
            width: 100%;
        }
        .bar {
            display: inline-block;
            background: var(--bs-blue);
            width: 100%;
        }
    `;

    getHeight(value: number): number {
        const max = Math.max(...this.values);
        return 100 * value / max;
    }

    renderRow(value: number, index: number): TemplateResult {
        return html`<div
            class="bar"
            style="height: ${this.getHeight(value)}%"
            title="${index}: ${value}">
            </div>`;
    }

    render(): TemplateResult[] {
        return this.values.map((v, i) => this.renderRow(v, i));
    }
}

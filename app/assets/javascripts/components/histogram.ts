import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

/**
 * This component displays a simple histogram using a flex layout and styled divs.
 * It always takes up 100% of the space it's given.
 *
 * @element dodona-histogram
 *
 * @prop {number[]} values - Pass the histogram data as an array of numbers.
 *
 * @cssprop [--d-histogram-baseline=lightgray] - The color of the bottom border serving as an axis.
 * @cssprop [--d-histogram-bar=steelblue] - The color of the bars.
 */
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
            border-bottom: 1px solid var(--d-histogram-baseline, lightgray);
        }
        .bar {
            display: inline-block;
            width: 100%;
            background: var(--d-histogram-bar, steelblue);
        }
    `;

    /**
     * Calculates the height of a bar, proportionate to the max value of the dataset.
     *
     * @param {number} value - The value associated with the current bar.
     * @return {number} The percentage value of the height of the bar.
     */
    private getHeight(value: number): number {
        const max = Math.max(...this.values);
        return 100 * value / max;
    }

    private renderBar(value: number, index: number): TemplateResult {
        return html`<div
            class="bar"
            style="height: ${this.getHeight(value)}%"
            title="${index}: ${value}">
            </div>`;
    }

    render(): TemplateResult[] {
        return this.values.map((v, i) => this.renderBar(v, i));
    }
}

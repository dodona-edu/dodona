import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { initTooltips } from "../utilities";
import { i18n } from "i18n/i18n";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * This component displays a progress bar consisting of consecutive divs
 * The divs are scaled according to the given values
 * The divs have an opacity according to their index
 *
 * @element d-progress-bar
 *
 * @prop {number[]} values - Pass the data as an array.
 * @prop {string} titleKey - The key of the title to be displayed in the tooltip.
 */
@customElement("d-progress-bar")
export class ProgressBar extends DodonaElement {
    @property({ type: Array })
    values: Array<number>;

    @property({ type: String, attribute: "title-key" })
    titleKey: string;

    get valuesSum(): number {
        return Object.values(this.values).reduce((a, b) => a + b, 0);
    }

    private getWidth(value: number): number {
        return 100 * value / this.valuesSum;
    }

    private getOpacity(key: number): number {
        return (key / (this.values.length - 1)) * 0.8 + 0.2;
    }

    private getTitle(value: number, index: number): string {
        return i18n.t(this.titleKey + i18n.t(this.titleKey + ".key", index), { index: index, smart_count: value });
    }

    updated(changedProperties: PropertyValues): void {
        initTooltips(this);
        super.updated(changedProperties);
    }

    private renderBar(value: number, index: number): TemplateResult {
        return html`<div
            class="bar"
            style="width: ${this.getWidth(value)}%; opacity: ${this.getOpacity(index)}; "
            title=${this.getTitle(value, index)}
            data-bs-toggle='tooltip'>
            </div>`;
    }

    render(): TemplateResult[] {
        return this.values.map( (v, i) => this.renderBar(v, i)).reverse();
    }
}

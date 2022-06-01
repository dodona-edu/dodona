import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult } from "lit";
import { ref } from "lit/directives/ref.js";
import { searchQuery } from "search";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

/**
 * This is a very simple clickable component
 * It sets a given query param to a given value when clicked
 *
 * @element d-filter-button
 *
 * @prop {string} param - the searchQuery param to be used
 * @prop {string} value - the value to be used in the searchQuery
 * @prop {boolean} multi - should be specified in case of array query params
 *
 * @slot - this contains the clickable button content
 */
@customElement("d-filter-button")
export class FilterButton extends LitElement {
    @property({ type: String })
    param: string;
    @property({ type: String })
    value: string;
    @property({ type: Boolean })
    multi = false;

    static styles = css`
        :host {
          cursor: pointer;
        }
    `;

    addFilter(): void {
        if (this.multi) {
            const selected = new Set(searchQuery.arrayQueryParams.params.get(this.param));
            selected.add(this.value);
            searchQuery.arrayQueryParams.updateParam(this.param, Array.from(selected));
        } else {
            searchQuery.queryParams.updateParam(this.param, this.value);
        }
    }

    render(): TemplateResult {
        return html`<slot @click=${() => this.addFilter()}></slot>`;
    }
}

/**
 * This is a clickable filter icon
 * When clicked it sets the query param 'filter' to the given value
 *
 * @element d-filter-icon
 *
 * @prop {string} value - the value to be used in the searchQuery
 * @prop {string} title - the title text that should be displayed when hovering the icon
 */
@customElement("d-filter-icon")
export class FilterIcon extends ShadowlessLitElement {
    @property({ type: String })
    value: string;
    @property({ type: String })
    title: string;

    element: Element;

    initialiseTooltip(e: Element): void {
        if (e) {
            this.element = e;
            const tooltip = window.bootstrap.Tooltip.getInstance(this.element);
            if (!tooltip) {
                new window.bootstrap.Tooltip(this.element);
            }
        }
    }

    disconnectedCallback(): void {
        const tooltip = window.bootstrap.Tooltip.getInstance(this.element);
        tooltip.hide();
        super.disconnectedCallback();
    }

    render(): TemplateResult {
        return html`
        <d-filter-button param="filter" .value=${this.value}>
            <i class="mdi mdi-filter-outline mdi-18 filter-icon"
               title="${this.title}"
               data-bs-toggle="tooltip"
               data-bs-placement="top"
               ${ref(r => this.initialiseTooltip(r))}
            >
            </i>
        </d-filter-button>
        `;
    }
}

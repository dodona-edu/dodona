import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, PropertyValues, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { initTooltips } from "util.js";
import { searchQueryState } from "state/SearchQuery";
import { StateController } from "state/state_system/StateController";

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

    state = new StateController(this);

    static styles = css`
        :host {
          cursor: pointer;
        }
    `;

    addFilter(e: Event): void {
        e.preventDefault();
        e.stopPropagation();
        if (this.multi) {
            const selected = new Set(searchQueryState.arrayQueryParams.get(this.param));
            selected.add(this.value);
            searchQueryState.arrayQueryParams.set(this.param, Array.from(selected));
        } else {
            searchQueryState.queryParams.set(this.param, this.value);
        }
    }

    render(): TemplateResult {
        return html`<slot @click=${e => this.addFilter(e)}></slot>`;
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
    @property({ type: String, attribute: "icon-title" })
    iconTitle: string;

    protected update(changedProperties: PropertyValues): void {
        super.update(changedProperties);
        initTooltips(this);
    }

    disconnectedCallback(): void {
        initTooltips();
    }

    render(): TemplateResult {
        return html`
        <d-filter-button param="filter" .value=${this.value}>
            <i class="mdi mdi-filter-outline mdi-18 filter-icon"
               title="${this.iconTitle}"
               data-bs-toggle="tooltip"
               data-bs-placement="top"
            >
            </i>
        </d-filter-button>
        `;
    }
}

import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { ref, Ref, createRef } from "lit/directives/ref.js";
import { watchMixin } from "components/watch_mixin";

type Option = {label: string, value: string, extra?: string};

/**
 * This component represents an input field with a datalist with possible options for the input.
 *
 * @element d-datalist-input
 *
 * @prop {String} name - name of the input field (used in form submit)
 * @prop {[{label: string, value: string, extra?: string}]} options - The label is used to match the user input, while the value is sent to the server.
 *          If the user input does not match any label, the value sent to the server wil be ""
 *          The extra string is added in the options and also used to match the input
 * @prop {String} value - the initial value for this field
 * @prop {String} placeholder - placeholder text shown in input
 *
 * @fires input - on value change, event details contain {label: string, value: string}
 */
@customElement("d-datalist-input")
export class DatalistInput extends watchMixin(ShadowlessLitElement) {
    @property({ type: String })
    name: string;
    @property({ type: Array })
    options: Option[];
    @property({ type: String })
    value: string;
    @property({ type: String })
    placeholder: string;

    inputRef: Ref<HTMLInputElement> = createRef();
    hiddenInputRef: Ref<HTMLInputElement> = createRef();

    @property({ state: true })
    filter: string = this.label;

    watch = {
        filter: () => {
            const option = this.options.find(option => option.label === this.filter);
            this.hiddenInputRef.value.value = option ? option.value : "";
            const event = new CustomEvent("input", {
                detail: { value: this.hiddenInputRef.value.value, label: this.filter },
                bubbles: true,
                composed: true
            });
            this.dispatchEvent(event);
        },
        value: () => {
            this.filter = this.label;
        }
    };

    get label(): string {
        const option = this.options.find(option => option.value === this.value);
        return option?.label;
    }

    get filtered_options(): Option[] {
        return this.options.filter(option => option.label.toLowerCase().includes(this.filter.toLowerCase()));
    }

    select(option: Option, e: Event): void {
        e.preventDefault();
        e.stopPropagation();
    }

    processInput(e): void {
        this.filter = this.inputRef.value.value;
        e.stopPropagation();
    }

    render(): TemplateResult {
        return html`
            <div class="dropdown">
                <input class="form-control search-filter"
                       type="text"
                       ${ref(this.inputRef)}
                       @input=${e => this.processInput(e)}
                       .value="${this.filter}"
                       placeholder="${this.placeholder}"
                >
                <ul class="dropdown-menu ${this.filter && this.hasSuggestions ? "show-search-dropdown" : ""}">
                    ${this.filtered_options.map(option => html`
                        <li><a class="dropdown-item" @click=${ e => this.select(option, e)}>
                            ${option.label}
                            ${option.extra ? html`
                                <p class="small">${option.extra}</p>
                            `:""}
                        </a></li>
                    `)}
                </ul>
            </div>
            <input type="hidden" name="${this.name}" ${ref(this.hiddenInputRef)} value="${this.value}">
        `;
    }
}

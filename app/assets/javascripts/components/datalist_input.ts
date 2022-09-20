import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { ref, Ref, createRef } from "lit/directives/ref.js";
import { watchMixin } from "components/watch_mixin";

export type Option = {label: string, value: string, extra?: string};

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
 * @prop {String} filter - the initial filter value for this field
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
    filter: string = this.label;
    @property({ type: String })
    placeholder: string;

    inputRef: Ref<HTMLInputElement> = createRef();

    watch = {
        filter: () => {
            if (!this.value) {
                this.value = this.options.find(o => this.filter === o.label)?.value || "";
            }
            this.fireEvent();
        },
        options: () => {
            if (!this.filter) {
                this.filter = this.label;
            }

            // If we can find a result amongst the filtered options
            // dispatch an event
            if (!this.value) {
                this.value = this.options.find(o => this.filter === o.label)?.value || "";
                if (this.value) {
                    this.fireEvent();
                }
            }
        }
    };

    fireEvent(): void {
        if (this.value) {
            const event = new CustomEvent("input", {
                detail: { value: this.value, label: this.filter },
                bubbles: true,
                composed: true
            });
            this.dispatchEvent(event);
        }
    }

    get label(): string {
        const option = this.options?.find(option => option.value === this.value);
        return option?.label || "";
    }

    get filtered_options(): Option[] {
        return this.options?.filter(option =>
            option.label.toLowerCase().includes(this.filter?.toLowerCase()) ||
            option.extra?.toLowerCase().includes(this.filter?.toLowerCase())
        );
    }

    get dropdown_top(): number {
        return this.inputRef.value?.getBoundingClientRect().bottom;
    }

    get dropdown_left(): number {
        return this.inputRef.value?.getBoundingClientRect().left;
    }

    get dropdown_width(): number {
        const rect = this.inputRef.value?.getBoundingClientRect();
        return rect?.right - rect?.left;
    }

    connectedCallback(): void {
        super.connectedCallback();
        // We are using fixed positioning for the dropdown to overcome issues with bounding boxes
        // This also means we have to rerender the dropdown in the correct position when the user scrolls
        window.addEventListener("scroll", () => this.requestUpdate());
    }

    select(option: Option, e: Event): void {
        e.preventDefault();
        e.stopPropagation();
        this.value = option.value;
        this.filter = option.label;
    }

    processInput(e): void {
        const input = this.inputRef.value.value;
        this.value = "";
        this.filter = input;
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
                <ul class="dropdown-menu ${this.filter && this.filtered_options.length > 0 ? "show-search-dropdown" : ""}"
                    style="position: fixed; top: ${this.dropdown_top}px; left: ${this.dropdown_left}px; max-width: ${this.dropdown_width}px; overflow-x: hidden;">
                    ${this.filtered_options.map(option => html`
                        <li><a class="dropdown-item ${this.value === option.value ? "active" :""} " @click=${ e => this.select(option, e)} style="cursor: pointer;">
                            ${option.label}
                            ${option.extra ? html`
                                <br/><span class="small">${option.extra}</span>
                            `:""}
                        </a></li>
                    `)}
                </ul>
            </div>
            <input type="hidden" name="${this.name}" .value="${this.value}">
        `;
    }
}

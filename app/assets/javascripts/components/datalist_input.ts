import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { ref, Ref, createRef } from "lit/directives/ref.js";
import { watchMixin } from "components/meta/watch_mixin";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { htmlEncode } from "util.js";

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
 * @prop {String} placeholder - placeholder text shown in input
 *
 * @fires input - on value change, event details contain {label: string, value: string}
 */
@customElement("d-datalist-input")
export class DatalistInput extends watchMixin(ShadowlessLitElement) {
    @property({ type: String })
    name: string;
    @property({ type: Array })
    options: Option[] = [];
    @property({ type: String })
    value: string;
    @property({ type: String })
    placeholder: string;

    inputRef: Ref<HTMLInputElement> = createRef();

    @property({ state: true })
    _filter= this.label;
    @property({ state: true })
    _softSelectedOption: Option;

    @property({ type: String })
    get filter(): string {
        return this._filter;
    }

    set filter(value: string) {
        this._filter = value;
        this.value = this.options?.find(o => this.filter === o.label)?.value || "";
        this.fireEvent();
    }

    @property({ state: true })
    get softSelectedOption(): Option {
        return this._softSelectedOption ||
            this.filtered_options.find(o => o.value === this.value) ||
            this.filtered_options[0] ||
            undefined;
    }

    set softSelectedOption(value: Option) {
        this._softSelectedOption = value;
    }

    watch = {
        options: () => {
            if (!this.filter) {
                this._filter = this.label;
            }

            // If we can find a result amongst the filtered options
            // dispatch an event
            if (!this.value) {
                this.value = this.options?.find(o => this.filter === o.label)?.value || "";
                if (this.value) {
                    this.fireEvent();
                }
            }
        }
    };

    fireEvent(): void {
        const event = new CustomEvent("input", {
            detail: { value: this.value, label: this.filter },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(event);
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
        this.filter = option.label;
    }

    processInput(e): void {
        const input = this.inputRef.value.value;
        this.filter = input;
        e.stopPropagation();
    }

    isSoftSelected(option: Option): boolean {
        return this.softSelectedOption === option || (
            this.softSelectedOption !== undefined &&
            option !== undefined &&
            this.softSelectedOption.label === option.label &&
            this.softSelectedOption.value === option.value
        );
    }

    keydown(e: KeyboardEvent): void {
        if ((e.key === "Tab" || e.key === "Enter") && this.softSelectedOption) {
            this.value = this.softSelectedOption.value;
            this.filter = this.softSelectedOption.label;
        }
        // When pressing enter while in this component, the default action shouldn't happen
        // e.g. when used in a form, enter will save the entire form
        if (e.key === "Enter") {
            e.preventDefault();
        }

        if (e.key === "ArrowDown") {
            e.preventDefault();
            const index = this.filtered_options.findIndex(o => this.isSoftSelected(o));
            this.softSelectedOption = this.filtered_options[(index + 1) % this.filtered_options.length];
        } else if (e.key === "ArrowUp") {
            e.preventDefault();
            const index = this.filtered_options.findIndex(o => this.isSoftSelected(o));
            this.softSelectedOption = this.filtered_options[(index - 1 + this.filtered_options.length) % this.filtered_options.length];
        } else {
            this.softSelectedOption = undefined;
        }
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        this.getElementsByClassName("active")[0]?.scrollIntoView({ block: "nearest" });
    }

    mark(s: string): TemplateResult {
        return this.filter ?
            html`${unsafeHTML(htmlEncode(s).replace(new RegExp(this.filter, "gi"), m => `<b>${m}</b>`))}` :
            html`${s}`;
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
                       @keydown=${e => this.keydown(e)}
                       @focus=${() => this.requestUpdate()}
                >
                <ul class="dropdown-menu ${this.filtered_options.length > 0 ? "show-search-dropdown" : ""}"
                    style="position: fixed; top: ${this.dropdown_top}px; left: ${this.dropdown_left}px; max-width: ${this.dropdown_width}px; overflow-x: hidden;">
                    ${this.filtered_options.map(option => html`
                        <li><a class="dropdown-item ${this.isSoftSelected(option) ? "active" :""} " @click=${ e => this.select(option, e)} style="cursor: pointer;">
                            ${this.mark(option.label)}
                            ${option.extra ? html`
                                <br/><span class="small">${this.mark(option.extra)}</span>
                            `:""}
                        </a></li>
                    `)}
                </ul>
            </div>
            <input type="hidden" name="${this.name}" .value="${this.value}">
        `;
    }
}

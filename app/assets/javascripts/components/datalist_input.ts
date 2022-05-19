import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { ref, Ref, createRef } from "lit/directives/ref.js";

/**
 * This component represents an input field with a datalist with possible options for the input.
 * The options have a label and a value.
 * The label is used to match the user input, while the value is sent to the server.
 * If the user input does not match any label, the value sent to the server wil be ""
 */
@customElement("dodona-datalist-input")
export class DatalistInput extends ShadowlessLitElement {
    @property({ type: String })
    name: string;
    @property({ type: Array })
    options: [{label: string, value: string}];
    @property({ type: String })
    value: string;

    inputRef: Ref<HTMLInputElement> = createRef();
    hiddenInputRef: Ref<HTMLInputElement> = createRef();

    get label(): string {
        const option = this.options.find(option => option.value === this.value);
        return option?.label;
    }

    processInput(): void {
        const option = this.options.find(option => option.label === this.inputRef.value.value);
        this.hiddenInputRef.value.value = option ? option.value : "";
    }

    render(): TemplateResult {
        return html`
            <input class="form-control" type="text" list="${this.name}-datalist-hidden" ${ref(this.inputRef)} @input=${() => this.processInput()}  value="${this.label}">
            <datalist id="${this.name}-datalist-hidden">
                ${this.options.map(option => html`<option value="${option.label}">${option.label}</option>`)}
            </datalist>
            <input type="hidden" name="${this.name}" ${ref(this.hiddenInputRef)} value="${this.value}">
        `;
    }
}

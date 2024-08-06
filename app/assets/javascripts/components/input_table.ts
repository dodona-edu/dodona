/**
 * This component creates an excel-like table with input fields.
 *
 * It recieves data in the format of a 2D array, and renders the table accordingly.
 * It always shows an empty row at the end, to allow for adding new rows.
 *
 * It als takes an optional 'headers' property, which is an array of strings to be used as headers.
 *
 *
 */

import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";

type CellData = string | number | boolean;

@customElement("d-input-table")
export class DInputTable extends LitElement {
    @property({ type: Array })
    data: Record<string, CellData>[] = [];
    @property({ type: Object })
    headers: Record<string, string> = {};
    @property({ type: Array })
    columns: string[] = [];
    @property({ type: Array })
    required: string[] = [];

    @property({ type: Array, state: true })
    private errors: Record<number, Record<string, string>> = {};

    updateValue(e: Event, row: Record<string, CellData>, col: string, index: number): void {
        const target = e.target as HTMLInputElement;
        const value = target.value;
        const newRow = { ...row, [col]: value };
        if (this.checkErrors(newRow, index)) {
            return;
        }
        const event = new CustomEvent("update", {
            detail: newRow
        });
        this.dispatchEvent(event);
    }

    checkErrors(row: Record<string, CellData>, index: number): boolean {
        let hasError = false;
        this.errors[index] = {};
        this.required.forEach(col => {
            if (!row[col]) {
                if (!this.errors[index]) {
                    this.errors[index] = {};
                }
                this.errors[index][col] = "This field is required";
                hasError = true;
            } else {
                delete this.errors[index][col];
            }
        });
        if (!hasError) {
            delete this.errors[index];
        }

        return hasError;
    }

    render(): TemplateResult {
        return html`
            <table>
                <thead>
                    <tr>
                        ${this.columns.map(col => html`<th>${col}</th>`)}
                    </tr>
                </thead>
                <tbody>
                    ${this.data.map((row, index) => html`
                        <tr>
                            ${this.columns.map(col => html`
                                <td>
                                    <input type="text"
                                           .value=${row[col]}
                                           @input=${(e: Event) => this.updateValue(e, row, col, index)}
                                           class="${this.errors[index] && this.errors[index][col] ? "error" : ""}"
                                    />
                                </td>
                            `)}
                        </tr>
                    `)}
                    <tr>
                        ${this.columns.map(col => html`
                            <td>
                                <input
                                    type="text"
                                    @input=${(e: Event) => this.updateValue(e, {}, col, this.data.length)}
                                    class="${this.errors[this.data.length] && this.errors[this.data.length][col] ? "error" : ""}"
                                />
                            </td>
                        `)}
                    </tr>
                </tbody>
            </table>
        `;
    }
}

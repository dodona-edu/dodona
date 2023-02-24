import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/hidden_annotations_dot";
import "components/annotations/annotations_cell";


@customElement("d-code-listing-row")
export class CodeListingRow extends ShadowlessLitElement {
    @property({ type: Number })
    row: number;
    @property({ type: String })
    renderedCode: string;

    @property({ state: true })
    showForm: boolean;

    render(): TemplateResult {
        return html`
                <td class="rouge-gutter gl">
                    <button class="btn btn-icon btn-icon-filled bg-primary annotation-button"
                            @click=${() => this.showForm = !this.showForm}
                            title="Toevoegen">
                        <i class="mdi mdi-comment-plus-outline mdi-18"></i>
                    </button>
                    <d-hidden-annotations-dot .row=${this.row}></d-hidden-annotations-dot>
                    <pre>${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre>${unsafeHTML(this.renderedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.showForm = false}
                    ></d-annotations-cell>
                </td>
        `;
    }
}

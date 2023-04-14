import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/hidden_annotations_dot";
import "components/annotations/annotations_cell";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips } from "util.js";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { annotationState } from "state/Annotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { Mark } from "components/annotations/mark";
import { ref } from "lit/directives/ref.js";

/**
 * This component represents a row in the code listing.
 * It contains the line number and the code itself, and the button to add a new annotation for this row.
 * It also contains the annotations for this row.
 *
 * @element d-code-listing-row
 *
 * @prop {number} row - The row number.
 * @prop {string} renderedCode - The code to display.
 */
@customElement("d-code-listing-row")
export class CodeListingRow extends i18nMixin(ShadowlessLitElement) {
    @property({ type: Number })
    row: number;
    @property({ type: String })
    renderedCode: string;

    @property({ state: true })
    showForm: boolean;

    markInstance: Mark;

    firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
    }

    get canCreateAnnotation(): boolean {
        return userState.hasPermission("annotation.create");
    }

    get addAnnotationTitle(): string {
        return annotationState.isQuestionMode ? I18n.t("js.annotations.options.add_question") : I18n.t("js.annotations.options.add_annotation");
    }

    get machineAnnotations(): MachineAnnotationData[] {
        return machineAnnotationState.byLine.get(this.row) || [];
    }

    initMarkInstance(pre: Element): void {
        this.markInstance = new Mark(pre);
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        this.markInstance.unmark({
            done: () => {
                const ranges = this.machineAnnotations.map(a => ({ start: a.column, length: a.columns, annotation: a }));
                this.markInstance.markRanges(ranges, {
                    debug: true,
                    each: (node, range) => {
                        console.log("Marking range", range);
                    }
                });
            },
        });
    }


    render(): TemplateResult {
        return html`
                <td class="rouge-gutter gl">
                    ${this.canCreateAnnotation ? html`
                        <button class="btn btn-icon btn-icon-filled bg-primary annotation-button"
                                @click=${() => this.showForm = true}
                                data-bs-toggle="tooltip"
                                data-bs-placement="top"
                                data-bs-trigger="hover"
                                title="${this.addAnnotationTitle}">
                            <i class="mdi mdi-comment-plus-outline mdi-18"></i>
                        </button>
                    ` : html``}
                    <d-hidden-annotations-dot .row=${this.row}></d-hidden-annotations-dot>
                    <pre>${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre ${ref(this.initMarkInstance)}>${unsafeHTML(this.renderedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.showForm = false}
                    ></d-annotations-cell>
                </td>
        `;
    }
}

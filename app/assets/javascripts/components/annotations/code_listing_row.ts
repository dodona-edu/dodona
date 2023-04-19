import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/hidden_annotations_dot";
import "components/annotations/annotations_cell";
import "components/annotations/machine_annotation_marker";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips } from "util.js";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { annotationState } from "state/Annotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { MachineAnnotationMarker } from "components/annotations/machine_annotation_marker";
import { wrapRangesInHtml, range } from "mark";

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

    /**
     * Calculates the range of the code that is covered by the given annotation.
     * If the annotation spans multiple lines, the range will be the whole line unless this is the first or last line.
     * In that case, the range will be the part of the line that is covered by the annotation.
     * @param annotation The annotation to calculate the range for.
     */
    getRangeFromAnnotation(annotation: MachineAnnotationData): range {
        const rowsLength = annotation.rows ?? 1;
        const lastRow = annotation.row + rowsLength ?? 0;
        const firstRow = annotation.row + 1 ?? 0;

        let start = 0;
        if (this.row === firstRow) {
            start = annotation.column || 0;
        }

        let length = Infinity;
        if (this.row === lastRow) {
            if (annotation.column !== undefined && annotation.column !== null) {
                length = annotation.columns || 0;
            }
        }

        return { start: start, length: length, data: annotation };
    }

    get wrappedCode(): string {
        return wrapRangesInHtml(
            this.renderedCode,
            this.machineAnnotationToMark.map(a => this.getRangeFromAnnotation(a)),
            "d-machine-annotation-marker",
            (node: MachineAnnotationMarker, range) => {
                // these nodes will be recompiled to html, so we need to store the data in a json string
                const annotations = JSON.parse(node.getAttribute("annotations")) || [];
                annotations.push(range.data);
                node.setAttribute("annotations", JSON.stringify(annotations));
            });
    }

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

    get machineAnnotationToMark(): MachineAnnotationData[] {
        return machineAnnotationState.byMarkedLine.get(this.row) || [];
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
                    <pre style="overflow: visible; display: inline-block;" >${unsafeHTML(this.wrappedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.showForm = false}
                    ></d-annotations-cell>
                </td>
        `;
    }
}

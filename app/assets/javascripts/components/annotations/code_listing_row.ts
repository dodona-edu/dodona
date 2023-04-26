import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/hidden_annotations_dot";
import "components/annotations/annotations_cell";
import "components/annotations/annotation_marker";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips, sleep } from "util.js";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { AnnotationData, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { wrapRangesInHtml, range } from "mark";
import { UserAnnotationData, userAnnotationState } from "state/UserAnnotations";
import { AnnotationMarker } from "components/annotations/annotation_marker";
import tippy, { createSingleton, Instance as Tippy, followCursor } from "tippy.js";
import { timeout } from "d3";

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
    tippyInstance: Tippy;

    renderTooltip(): void {
        if (this.tippyInstance) {
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }

        const tooltip = document.createElement("div");
        tooltip.innerHTML = "TEST";

        this.tippyInstance = tippy(this, {
            content: tooltip,
            trigger: "manual",
            followCursor: "initial",
            interactive: true,
            interactiveDebounce: 25,
            delay: [0, 25],
            offset: [-10, 2],
            appendTo: () => document.querySelector(".code-table"),
            plugins: [followCursor],
        });
    }

    async triggerTooltip(): Promise<void> {
        // Wait for the selection to be updated
        await sleep(10);
        if (!window.getSelection().isCollapsed) {
            this.tippyInstance.show();
        } else {
            this.tippyInstance.hide();
        }
    }

    /**
     * Calculates the range of the code that is covered by the given annotation.
     * If the annotation spans multiple lines, the range will be the whole line unless this is the first or last line.
     * In that case, the range will be the part of the line that is covered by the annotation.
     * @param annotation The annotation to calculate the range for.
     */
    getRangeFromAnnotation(annotation: AnnotationData): range {
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
        const annotationsToMark = [...this.userAnnotationsToMark, ...this.machineAnnotationsToMark];
        return wrapRangesInHtml(
            this.renderedCode,
            annotationsToMark.map(a => this.getRangeFromAnnotation(a)),
            "d-annotation-marker",
            (node: AnnotationMarker, range) => {
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

    get machineAnnotationsToMark(): MachineAnnotationData[] {
        return machineAnnotationState.byMarkedLine.get(this.row) || [];
    }

    get userAnnotationsToMark(): UserAnnotationData[] {
        return userAnnotationState.rootIdsByMarkedLine.get(this.row)?.map(i => userAnnotationState.byId.get(i)) || [];
    }

    render(): TemplateResult {
        this.renderTooltip();

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
                    <pre style="user-select: none;">${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre class="code-line" style="overflow: visible; display: inline-block;" @pointerup="${() => this.triggerTooltip()}" >${unsafeHTML(this.wrappedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.showForm = false}
                    ></d-annotations-cell>
                </td>
        `;
    }
}

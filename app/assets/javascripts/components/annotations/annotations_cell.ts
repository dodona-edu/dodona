import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { UserAnnotationFormData, userAnnotationState } from "state/UserAnnotations";
import { annotationState, compareAnnotationOrders } from "state/Annotations";
import { submissionState } from "state/Submissions";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import "components/annotations/machine_annotation";
import "components/annotations/user_annotation";
import "components/annotations/annotation_form";
import "components/annotations/thread";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import { evaluationState } from "state/Evaluations";

/**
 * This component represents a cell that groups all annotations for a specific line.
 * It also contains the form for creating new annotations.
 *
 * @element d-annotations-cell
 *
 * @prop {Number} row - the line number
 * @prop {Boolean} formShown - if the form should be shown
 *
 * @fires close-form - if the form should be closed
 */
@customElement("d-annotations-cell")
export class AnnotationsCell extends ShadowlessLitElement {
    @property({ type: Boolean, attribute: "show-form" })
    formShown: boolean;
    @property({ type: Number })
    row: number;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    get machineAnnotations(): MachineAnnotationData[] {
        return machineAnnotationState.byLine.get(this.row) || [];
    }

    get userAnnotationIds(): number[] {
        return userAnnotationState.rootIdsByLine.get(this.row) || [];
    }


    async createAnnotation(e: CustomEvent): Promise<void> {
        const annotationData: UserAnnotationFormData = {
            "annotation_text": e.detail.text,
            "line_nr": this.row,
            "evaluation_id": evaluationState.id,
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
        };

        if (this.row > 0 && userAnnotationState.selectedRange) {
            annotationData["line_nr"] = userAnnotationState.selectedRange.row;
            annotationData["rows"] = userAnnotationState.selectedRange.rows;
            annotationData["column"] = userAnnotationState.selectedRange.column;
            annotationData["columns"] = userAnnotationState.selectedRange.columns;
        }

        try {
            const mode = annotationState.isQuestionMode ? "question" : "annotation";
            await userAnnotationState.create(annotationData, submissionState.id, mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);
            this.closeForm();
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    closeForm(): void {
        const event = new CustomEvent("close-form", { bubbles: true, composed: true });
        this.dispatchEvent(event);
    }

    protected render(): TemplateResult {
        return html`
            <div class="annotation-cell">
                ${this.formShown ? html`
                    <div class="annotation ${annotationState.isQuestionMode ? "question" : "user" }">
                        <d-annotation-form @submit=${e => this.createAnnotation(e)}
                                           @cancel=${() => this.closeForm()}
                                           ${ref(this.annotationFormRef)}
                                           submit-button-text="send"
                        ></d-annotation-form>
                    </div>
                ` : ""}
                ${this.userAnnotationIds.map(a => html`
                    <d-thread .rootId=${a}></d-thread>
                `)}
                ${this.machineAnnotations
        .filter(a => annotationState.isVisible(a))
        .sort(compareAnnotationOrders).map(a => html`
                        <d-machine-annotation .data=${a}></d-machine-annotation>
                `)}
            </div>
        `;
    }
}

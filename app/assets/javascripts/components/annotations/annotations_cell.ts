import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import {
    createUserAnnotation,
    getUserAnnotationsByLine,
    UserAnnotationData,
    UserAnnotationFormData
} from "state/UserAnnotations";
import { getEvaluationId } from "state/Evaluations";
import { annotationState } from "state/Annotations";
import { getSubmissionId } from "state/Submissions";
import { getMachineAnnotationsByLine, MachineAnnotationData } from "state/MachineAnnotations";
import "components/annotations/machine_annotation";
import "components/annotations/user_annotation";
import "components/annotations/annotation_form";
import "components/annotations/thread";
import { stateMixin } from "state/StateMixin";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";

/**
 * This component represents a cell that groups all annotations for a specific line.
 * It also contains the form for creating new annotations.
 *
 * @element d-annotations-cell
 *
 * @prop {Number} row - the line number
 * @prop {Boolean} showForm - if the form should be shown
 *
 * @fires close-form - if the form should be closed
 */
@customElement("d-annotations-cell")
export class AnnotationsCell extends stateMixin(ShadowlessLitElement) {
    @property({ type: Boolean, attribute: "show-form" })
    showForm: boolean;
    @property({ type: Number })
    row: number;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    state = ["getUserAnnotations", "getMachineAnnotations"];

    get machineAnnotations(): MachineAnnotationData[] {
        return getMachineAnnotationsByLine(this.row);
    }

    get userAnnotations(): UserAnnotationData[] {
        return getUserAnnotationsByLine(this.row);
    }


    async createAnnotation(e: CustomEvent): Promise<void> {
        const annotationData: UserAnnotationFormData = {
            "annotation_text": e.detail.text,
            "line_nr": this.row,
            "evaluation_id": getEvaluationId(),
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
        };

        try {
            const mode = annotationState.isQuestionMode ? "question" : "annotation";
            await createUserAnnotation(annotationData, getSubmissionId(), mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);
            this.closeForm();
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    getVisibleMachineAnnotationsOfType(type: string): TemplateResult[] {
        return this.machineAnnotations
            .filter(a => annotationState.isVisible(a))
            .filter(a => a.type === type).map(a => html`
                <d-machine-annotation .data=${a}></d-machine-annotation>
        `);
    }

    closeForm(): void {
        const event = new CustomEvent("close-form", { bubbles: true, composed: true });
        this.dispatchEvent(event);
    }

    protected render(): TemplateResult {
        return html`
            <div class="annotation-cell">
                ${this.showForm ? html`
                    <div class="annotation ${annotationState.isQuestionMode ? "question" : "user" }">
                        <d-annotation-form @submit=${e => this.createAnnotation(e)}
                                           @cancel=${() => this.closeForm()}
                                           ${ref(this.annotationFormRef)}
                                           submit-button-text="send"
                        ></d-annotation-form>
                    </div>
                ` : ""}
                <div class="annotation-group-error">
                    ${this.getVisibleMachineAnnotationsOfType("error")}
                </div>
                <div class="annotation-group-conversation">
                    ${this.userAnnotations.filter(a => annotationState.isVisible(a)).map(a => html`
                        <d-thread .data=${a}></d-thread>
                    `)}
                </div>
                <div class="annotation-group-warning">
                    ${this.getVisibleMachineAnnotationsOfType("warning")}
                </div>
                <div class="annotation-group-info">
                    ${this.getVisibleMachineAnnotationsOfType("info")}
                </div>
            </div>
        `;
    }
}

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
import { getQuestionMode, isAnnotationVisible } from "state/Annotations";
import { getSubmissionId } from "state/Submissions";
import { getMachineAnnotationsByLine, MachineAnnotationData } from "state/MachineAnnotations";
import "components/annotations/machine_annotation";
import "components/annotations/user_annotation";
import "components/annotations/annotation_form";
import "components/annotations/thread";
import { stateMixin } from "state/StateMixin";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";


@customElement("d-annotations-cell")
export class AnnotationsCell extends stateMixin(ShadowlessLitElement) {
    @property({ type: Boolean, attribute: "show-form" })
    showForm: boolean;
    @property({ type: Number })
    row: number;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    state = ["getUserAnnotations", "getMachineAnnotations", "isAnnotationVisible", "getQuestionMode"];

    get machineAnnotations(): MachineAnnotationData[] {
        return getMachineAnnotationsByLine(this.row);
    }

    get userAnnotations(): UserAnnotationData[] {
        return getUserAnnotationsByLine(this.row);
    }

    get questionMode(): boolean {
        return getQuestionMode();
    }


    async createAnnotation(e: CustomEvent): Promise<void> {
        const annotationData: UserAnnotationFormData = {
            "annotation_text": e.detail.text,
            "line_nr": this.row,
            "evaluation_id": getEvaluationId(),
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
        };

        try {
            const mode = getQuestionMode() ? "question" : "annotation";
            await createUserAnnotation(annotationData, getSubmissionId(), mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);
            this.closeForm();
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    getVisibleMachineAnnotationsOfType(type: string): TemplateResult[] {
        return this.machineAnnotations
            .filter(isAnnotationVisible)
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
                    <div class="annotation ${this.questionMode ? "question" : "user" }">
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
                    ${this.userAnnotations.filter(isAnnotationVisible).map(a => html`
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

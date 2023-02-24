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
import { stateMixin } from "state/StateMixin";


@customElement("d-annotations-cell")
export class AnnotationsCell extends stateMixin(ShadowlessLitElement) {
    @property({ type: Boolean, attribute: "show-form" })
    showForm: boolean;
    @property({ type: Number })
    row: number;

    state = ["getUserAnnotations", "getMachineAnnotations", "isAnnotationVisible"];

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
            const mode = getQuestionMode() ? "question" : "annotation";
            await createUserAnnotation(annotationData, getSubmissionId(), mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);

            const event = new CustomEvent("close-form", { bubbles: true, composed: true });
            this.dispatchEvent(event);
        } catch (err) {
            // annotationForm.hasErrors = true;
            // annotationForm.disabled = false;
        }
    }

    getVisibleMachineAnnotationsOfType(type: string): TemplateResult[] {
        return this.machineAnnotations
            .filter(isAnnotationVisible)
            .filter(a => a.type === type).map(a => html`
                <d-machine-annotation .data=${a}></d-machine-annotation>
        `);
    }

    protected render(): TemplateResult {
        return html`
            <div class="annotation-cell">
                ${this.showForm ? html`
                    <d-annotation-form @cancel=${() => this.showForm = false}
                                       @submit=${e => this.createAnnotation(e)}
                    ></d-annotation-form>
                ` : ""}
                <div class="annotation-group-error">
                    ${this.getVisibleMachineAnnotationsOfType("error")}
                </div>
                <div class="annotation-group-conversation">
                    ${this.userAnnotations.filter(isAnnotationVisible).map(a => html`
                        <d-user-annotation .data=${a}></d-user-annotation>
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

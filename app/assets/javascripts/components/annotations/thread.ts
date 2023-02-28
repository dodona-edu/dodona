import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { createUserAnnotation, UserAnnotationData, UserAnnotationFormData } from "state/UserAnnotations";
import { html, TemplateResult } from "lit";
import { getEvaluationId } from "state/Evaluations";
import { getQuestionMode } from "state/Annotations";
import { getSubmissionId } from "state/Submissions";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import { stateMixin } from "state/StateMixin";


@customElement("d-thread")
export class Thread extends stateMixin(ShadowlessLitElement) {
    @property({ type: Object })
    data: UserAnnotationData;

    @property({ state: true })
    showResponses = false;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    state = ["getUserAnnotations"];

    async createAnnotation(e: CustomEvent): Promise<void> {
        const annotationData: UserAnnotationFormData = {
            "annotation_text": e.detail.text,
            "line_nr": this.data.line_nr,
            "evaluation_id": getEvaluationId(),
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
            "thread_root_id": this.data.id,
        };

        try {
            const mode = getQuestionMode() ? "question" : "annotation";
            await createUserAnnotation(annotationData, getSubmissionId(), mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    render(): TemplateResult {
        return html`
            <d-user-annotation .data=${this.data}>
                <a class="btn btn-text with-icon annotation-edit"
                   @click="${() => this.showResponses = !this.showResponses}"
                   v-slot="buttons"
                >
                    <i class="mdi mdi-comment-plus-outline"></i> ${this.showResponses ? "Close thread" : "Reply"}
                </a>
            </d-user-annotation>
            ${this.showResponses ? html`
                <div style="margin-left: 1.5rem;">
                    <div class="responses">
                        ${this.data.responses.map(response => html`
                            <d-user-annotation .data=${response}></d-user-annotation>
                        `)}
                    </div>
                    <d-annotation-form @submit=${e => this.createAnnotation(e)}
                                       ${ref(this.annotationFormRef)}
                    ></d-annotation-form>
                </div>
            ` : ""}
        `;
    }
}

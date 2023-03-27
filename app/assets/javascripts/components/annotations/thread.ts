import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import {
    createUserAnnotation, invalidateUserAnnotation,
    transition, transitionAll,
    UserAnnotationData,
    UserAnnotationFormData
} from "state/UserAnnotations";
import { html, TemplateResult } from "lit";
import { getEvaluationId } from "state/Evaluations";
import { getQuestionMode } from "state/Annotations";
import { getSubmissionId } from "state/Submissions";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import { stateMixin } from "state/StateMixin";
import { i18nMixin } from "components/meta/i18n_mixin";

/**
 * This component represents a thread of annotations.
 * It also contains the form for creating new annotations.
 *
 * @element d-thread
 *
 * @prop {UserAnnotationData} data - the data of the root annotation for this thread
 */
@customElement("d-thread")
export class Thread extends i18nMixin(stateMixin(ShadowlessLitElement)) {
    @property({ type: Object })
    data: UserAnnotationData;

    @property({ state: true })
    showForm = false;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    state = ["getUserAnnotations", "getQuestionMode"];

    get questionMode(): boolean {
        return getQuestionMode();
    }

    get openQuestions(): UserAnnotationData[] | undefined {
        return [this.data, ...this.data.responses]
            .filter(response => response.question_state !== undefined && response.question_state !== "answered");
    }

    get isUnanswered(): boolean {
        return this.openQuestions.length > 0;
    }

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

            invalidateUserAnnotation(this.data.id);
            this.showForm = false;
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    markAsResolved(): void {
        transitionAll(this.openQuestions, "answered");
    }

    markAsInProgress(): void {
        transitionAll(this.openQuestions.filter(question => question.question_state !== "in_progress"), "in_progress");
    }

    markAsUnanswered(): void {
        transitionAll(this.openQuestions.filter(question => question.question_state !== "unanswered"), "unanswered");
    }

    addReply(): void {
        this.showForm = true;
        this.markAsInProgress();
    }

    cancelReply(): void {
        this.showForm = false;
        this.markAsUnanswered();
    }

    render(): TemplateResult {
        return html`

            <div class="thread">
                <d-user-annotation .data=${this.data}></d-user-annotation>
                ${this.data.responses.map(response => html`
                    <d-user-annotation .data=${response}></d-user-annotation>
                `)}
                ${this.showForm ? html`
                    <div class="annotation ${this.questionMode ? "question" : "user" }">
                        <d-annotation-form @submit=${e => this.createAnnotation(e)}
                                           ${ref(this.annotationFormRef)}
                                           @cancel=${() => this.cancelReply()}
                                           submit-button-text="reply"
                        ></d-annotation-form>
                    </div>
                ` : html`
                    <div class="fake-input">
                        <input type="text" class="form-control"
                               placeholder="${I18n.t("js.user_annotation.reply")}..."
                               @click="${() => this.addReply()}" />
                        ${this.isUnanswered ? html`
                            <span>${I18n.t("js.user_question.or")}</span>
                            <a class="btn btn-text" @click="${() => this.markAsResolved()}">
                                ${I18n.t("js.user_question.resolve")}
                            </a>
                        ` : html``}
                    </div>
                `}
            </div>
        `;
    }
}
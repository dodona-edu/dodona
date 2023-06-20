import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import {

    UserAnnotationData,
    UserAnnotationFormData, userAnnotationState
} from "state/UserAnnotations";
import { html, TemplateResult } from "lit";
import { submissionState } from "state/Submissions";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import { i18nMixin } from "components/meta/i18n_mixin";
import { annotationState } from "state/Annotations";
import { evaluationState } from "state/Evaluations";

/**
 * This component represents a thread of annotations.
 * It also contains the form for creating new annotations.
 *
 * @element d-thread
 *
 * @prop {number} rootId - the id of the root annotation for this thread
 */
@customElement("d-thread")
export class Thread extends i18nMixin(ShadowlessLitElement) {
    @property({ type: Number, attribute: "root-id" })
    rootId: number;

    @property({ state: true })
    showForm = false;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    get data(): UserAnnotationData {
        return userAnnotationState.byId.get(this.rootId);
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
            "evaluation_id": evaluationState.id,
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
            "thread_root_id": this.data.id,
        };

        try {
            const mode = annotationState.isQuestionMode ? "question" : "annotation";
            await userAnnotationState.create(annotationData, submissionState.id, mode, e.detail.saveAnnotation, e.detail.savedAnnotationTitle);
            this.showForm = false;
        } catch (err) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    markAsResolved(): void {
        userAnnotationState.transitionAll(this.openQuestions, "answered");
    }

    markAsInProgress(): void {
        userAnnotationState.transitionAll(this.openQuestions.filter(question => question.question_state !== "in_progress"), "in_progress");
    }

    markAsUnanswered(): void {
        userAnnotationState.transitionAll(this.openQuestions.filter(question => question.question_state !== "unanswered"), "unanswered");
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
        return this.data ? html`
            <div class="thread ${annotationState.isVisible(this.data) ? "" : "hidden"}"
                 @mouseenter="${() => annotationState.setHovered(this.data, true)}"
                 @mouseleave="${() => annotationState.setHovered(this.data, false)}"
            >
                <d-user-annotation .data=${this.data}></d-user-annotation>
                ${this.data.responses.map(response => html`
                    <d-user-annotation .data=${response}></d-user-annotation>
                `)}
                ${this.showForm ? html`
                    <div class="annotation ${annotationState.isQuestionMode ? "question" : "user" }">
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
        ` : html``;
    }
}

import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import "components/annotations/annotations_toggles";
import "components/annotations/hidden_annotations_dot";
import { i18nMixin } from "components/meta/i18n_mixin";
import { userState } from "state/Users";
import { annotationState } from "state/Annotations";
import { courseState } from "state/Courses";
import { exerciseState } from "state/Exercises";
import { submissionState } from "state/Submissions";


/**
 * This component represents the top row with options about annotations, that is displayed above the code listing.
 * It contains the button to add a new global annotation, the global annotations themselves and the toggles to show/hide annotations.
 *
 * @element d-annotation-options
 */
@customElement("d-annotation-options")
export class AnnotationOptions extends i18nMixin(ShadowlessLitElement) {
    @property({ state: true })
    formShown = false;

    get canCreateAnnotation(): boolean {
        return userState.hasPermission("annotation.create");
    }

    get canResubmitSubmission(): boolean {
        return userState.hasPermission("submission.submit_as_own");
    }

    get resubmitPath(): string {
        return `/courses/${courseState.id}/exercises/${exerciseState.id}/?edit_submission=${submissionState.id}`;
    }

    get addAnnotationTitle(): string {
        return annotationState.isQuestionMode ?
            I18n.t("js.annotations.options.add_global_question") :
            I18n.t("js.annotations.options.add_global_annotation");
    }

    protected render(): TemplateResult {
        return html`
            <div class="feedback-table-options">
                <d-hidden-annotations-dot .row=${0}></d-hidden-annotations-dot>
                ${this.canCreateAnnotation ? html`
                    <button class="btn btn-outline" @click="${() => this.formShown = true}">
                        ${this.addAnnotationTitle}
                    </button>
                ` : html``}
                ${this.canResubmitSubmission ? html`
                    <a class="btn btn-text resubmit-btn" href="${this.resubmitPath}" target="_blank">
                        ${I18n.t("js.feedbacks.submission.submit")}
                    </a>
                ` : html``}
                <span class="flex-spacer"></span>
                <d-annotations-toggles></d-annotations-toggles>
            </div>
            <div>
            <d-annotations-cell .row=${0}
                                .formShown="${this.formShown}"
                                @close-form=${() => this.formShown = false}
                ></d-annotations-cell>
            </div>
        `;
    }
}

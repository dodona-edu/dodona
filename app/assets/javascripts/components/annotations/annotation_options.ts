import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import "components/annotations/annotations_toggles";
import "components/annotations/hidden_annotations_dot";
import { userState } from "state/Users";
import { annotationState } from "state/Annotations";
import { submissionState } from "state/Submissions";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";


/**
 * This component represents the top row with options about annotations, that is displayed above the code listing.
 * It contains the button to add a new global annotation, the global annotations themselves and the toggles to show/hide annotations.
 *
 * @element d-annotation-options
 */
@customElement("d-annotation-options")
export class AnnotationOptions extends DodonaElement {
    @property({ state: true })
    formShown = false;

    get canCreateAnnotation(): boolean {
        return userState.hasPermission("annotation.create");
    }

    get addAnnotationTitle(): string {
        return annotationState.isQuestionMode ?
            i18n.t("js.annotations.options.add_global_question") :
            i18n.t("js.annotations.options.add_global_annotation");
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
                ${submissionState.canResubmitSubmission ? html`
                    <a class="btn btn-text resubmit-btn" href="${submissionState.resubmitPath}" target="_blank">
                        ${i18n.t("js.feedbacks.submission.submit")}
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

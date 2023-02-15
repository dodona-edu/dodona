import { UserAnnotation } from "components/annotations/user_annotation";
import { UserAnnotationData } from "code_listing/user_annotation";
import { QuestionState } from "code_listing/annotation";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
export interface QuestionAnnotationData extends UserAnnotationData {
    // eslint-disable-next-line camelcase
    question_state: QuestionState;
    // eslint-disable-next-line camelcase
    newer_submission_url: string | null;
}

@customElement("d-question-annotation")
export class QuestionAnnotation extends UserAnnotation {
    @property({ type: Object })
    data: QuestionAnnotationData;

    protected get meta(): TemplateResult {
        return html`
            ${super.meta}
            ${this.data.newer_submission_url !== null ? html`
                <span>
                    ·
                    <a href="${this.data.newer_submission_url}" target="_blank">
                        <i class="mdi mdi-information mdi-18 colored-info"
                           title="${I18n.t("js.user_question.has_newer_submission")}"
                           data-bs-toggle="tooltip"
                           data-bs-placement="top"
                        ></i>
                    </a>
                </span>
            ` : ""}
        `;
    }
}


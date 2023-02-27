import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { stateMixin } from "state/StateMixin";
import { getQuestionMode } from "state/Annotations";
import "components/annotations/annotations_toggles";
import "components/annotations/hidden_annotations_dot";
import { i18nMixin } from "components/meta/i18n_mixin";


@customElement("d-annotation-options")
export class AnnotationOptions extends i18nMixin(stateMixin(ShadowlessLitElement)) {
    @property({ state: true })
    showForm = false;

    state = ["getQuestionMode"];

    get questionMode(): boolean {
        return getQuestionMode();
    }

    protected render(): TemplateResult {
        return html`
            <div class="feedback-table-options">
                <d-hidden-annotations-dot .row=${0}></d-hidden-annotations-dot>
                <button class="btn btn-text" @click="${() => this.showForm = true}">
                    ${this.questionMode ? I18n.t("js.annotations.options.add_global_question") : I18n.t("js.annotations.options.add_global_annotation")}
                </button>
                <span class="flex-spacer"></span>
                <d-annotations-toggles></d-annotations-toggles>
            </div>
            <div>
            <d-annotations-cell .row=${0}
                                .showForm="${this.showForm}"
                                @close-form=${() => this.showForm = false}
                ></d-annotations-cell>
            </div>
        `;
    }
}

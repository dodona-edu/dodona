import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { stateMixin } from "state/StateMixin";
import "components/annotations/annotations_toggles";
import "components/annotations/hidden_annotations_dot";
import { i18nMixin } from "components/meta/i18n_mixin";
import { hasPermission } from "state/Users";
import { observeState } from "lit-element-state";
import { annotationState } from "state/Annotations";


/**
 * This component represents the top row with options about annotations, that is displayed above the code listing.
 * It contains the button to add a new global annotation, the global annotations themselves and the toggles to show/hide annotations.
 *
 * @element d-annotation-options
 */
@customElement("d-annotation-options")
export class AnnotationOptions extends observeState(i18nMixin(stateMixin(ShadowlessLitElement))) {
    @property({ state: true })
    showForm = false;

    state = ["hasPermission"];

    get canCreateAnnotation(): boolean {
        return hasPermission("annotation.create");
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
                    <button class="btn btn-text" @click="${() => this.showForm = true}">
                        ${this.addAnnotationTitle}
                    </button>
                ` : html``}
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

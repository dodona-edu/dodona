import { customElement } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { stateMixin } from "state/StateMixin";
import { html, TemplateResult, PropertyValues } from "lit";
import { AnnotationVisibilityOptions, getAnnotationVisibility, setAnnotationVisibility } from "state/Annotations";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips } from "util.js";

/**
 * This component represents the toggles to show/hide annotations.
 * It contains the buttons to show all annotations, only important annotations or no annotations.
 *
 * @element d-annotations-toggles
 */
@customElement("d-annotations-toggles")
export class AnnotationsToggles extends i18nMixin(stateMixin(ShadowlessLitElement)) {
    state = ["getAnnotationVisibility"];

    protected update(changedProperties: PropertyValues): void {
        super.update(changedProperties);
        initTooltips(this);
    }

    get annotationVisibility(): AnnotationVisibilityOptions {
        return getAnnotationVisibility();
    }

    protected render(): TemplateResult {
        return html`
            <span class="diff-switch-buttons switch-buttons">
                <span>${I18n.t("js.annotations.toggles.title")}</span>
                <div class="btn-group btn-toggle" role="group" aria-label="Annotaties" data-bs-toggle="buttons">
                    <button class="btn annotation-toggle ${this.annotationVisibility === "all" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${I18n.t("js.annotations.toggles.show_all")}"
                            @click=${() => setAnnotationVisibility("all")}
                    >
                        <i class="mdi mdi-comment-multiple-outline"></i>
                    </button>
                    <button class="btn annotation-toggle ${this.annotationVisibility === "important" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${I18n.t("js.annotations.toggles.show_errors")}"
                            @click=${() => setAnnotationVisibility("important")}>
                        <i class="mdi mdi-comment-alert-outline"></i>
                    </button>
                    <button class="btn annotation-toggle ${this.annotationVisibility === "none" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${I18n.t("js.annotations.toggles.hide_all")}"
                            @click=${() => setAnnotationVisibility("none")}>
                        <i class="mdi mdi-comment-remove-outline"></i>
                    </button>
                </div>
            </span>
        `;
    }
}

import { customElement } from "lit/decorators.js";
import { html, TemplateResult, PropertyValues } from "lit";
import { annotationState } from "state/Annotations";
import { initTooltips } from "utilities";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * This component represents the toggles to show/hide annotations.
 * It contains the buttons to show all annotations, only important annotations or no annotations.
 *
 * @element d-annotations-toggles
 */
@customElement("d-annotations-toggles")
export class AnnotationsToggles extends DodonaElement {
    protected update(changedProperties: PropertyValues): void {
        super.update(changedProperties);
        initTooltips(this);
    }

    protected render(): TemplateResult {
        return html`
            <span class="diff-switch-buttons switch-buttons">
                <span>${i18n.t("js.annotations.toggles.title")}</span>
                <div class="btn-group btn-toggle" role="group" aria-label="${i18n.t("js.annotations.toggles.title")}" data-bs-toggle="buttons">
                    <button class="btn annotation-toggle ${annotationState.visibility === "all" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${i18n.t("js.annotations.toggles.show_all")}"
                            @click=${() => annotationState.visibility = "all"}
                    >
                        <i class="mdi mdi-comment-multiple-outline"></i>
                    </button>
                    <button class="btn annotation-toggle ${annotationState.visibility === "important" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${i18n.t("js.annotations.toggles.show_errors")}"
                            @click=${() => annotationState.visibility = "important"}>
                        <i class="mdi mdi-comment-alert-outline"></i>
                    </button>
                    <button class="btn annotation-toggle ${annotationState.visibility === "none" ? "active" : ""}"
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${i18n.t("js.annotations.toggles.hide_all")}"
                            @click=${() => annotationState.visibility = "none"}>
                        <i class="mdi mdi-comment-remove-outline"></i>
                    </button>
                </div>
            </span>
        `;
    }
}

import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { MachineAnnotation, machineAnnotationState } from "state/MachineAnnotations";
import { UserAnnotation, userAnnotationState } from "state/UserAnnotations";
import { i18nMixin } from "components/meta/i18n_mixin";
import { PropertyValues } from "@lit/reactive-element/development/reactive-element";
import { initTooltips } from "utilities";
import { annotationState, compareAnnotationOrders } from "state/Annotations";

/**
 * This component represents a dot that shows the number of hidden annotations for a line.
 *
 * @element d-hidden-annotations-dot
 *
 * @prop {number} row - The row number.
 */
@customElement("d-hidden-annotations-dot")
export class HiddenAnnotationsDot extends i18nMixin(ShadowlessLitElement) {
    @property({ type: Number })
    row: number;

    get machineAnnotations(): MachineAnnotation[] {
        return machineAnnotationState.byLine.get(this.row) || [];
    }

    get userAnnotations(): UserAnnotation[] {
        return userAnnotationState.rootIdsByLine.get(this.row)?.map(id => userAnnotationState.byId.get(id)) || [];
    }

    get hiddenAnnotations(): (MachineAnnotation | UserAnnotation)[] {
        return [...this.machineAnnotations, ...this.userAnnotations].filter(a => !annotationState.isVisible(a));
    }

    get infoDotClasses(): string {
        const hiddenType = this.hiddenAnnotations.sort(compareAnnotationOrders)[0]?.type;
        return `dot-${hiddenType}`;
    }

    get infoDotTitle(): string {
        const count = this.hiddenAnnotations.length;
        if (count === 1) {
            return I18n.t("js.annotation.hidden.single");
        } else {
            return I18n.t("js.annotation.hidden.plural", { count: count });
        }
    }

    updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    render(): TemplateResult {
        if (this.hiddenAnnotations.length > 0) {
            return html`
                <span class="dot ${this.infoDotClasses}"
                      data-bs-toggle="tooltip"
                      data-bs-placement="top"
                      data-bs-trigger="hover"
                      title="${this.infoDotTitle}"></span>
            `;
        }

        return html``;
    }
}

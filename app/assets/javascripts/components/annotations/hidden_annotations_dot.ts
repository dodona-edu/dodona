import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { stateMixin } from "state/StateMixin";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { getUserAnnotationsByLine, UserAnnotationData } from "state/UserAnnotations";
import { i18nMixin } from "components/meta/i18n_mixin";
import { PropertyValues } from "@lit/reactive-element/development/reactive-element";
import { initTooltips } from "util.js";
import { annotationState } from "state/Annotations";

/**
 * This component represents a dot that shows the number of hidden annotations for a line.
 *
 * @element d-hidden-annotations-dot
 *
 * @prop {number} row - The row number.
 */
@customElement("d-hidden-annotations-dot")
export class HiddenAnnotationsDot extends i18nMixin(stateMixin(ShadowlessLitElement)) {
    @property({ type: Number })
    row: number;

    state = ["getUserAnnotations", "getMachineAnnotations"];

    get machineAnnotations(): MachineAnnotationData[] {
        return machineAnnotationState.byLine.get(this.row);
    }

    get userAnnotations(): UserAnnotationData[] {
        return getUserAnnotationsByLine(this.row);
    }

    get hiddenAnnotations(): (MachineAnnotationData | UserAnnotationData)[] {
        return [...this.machineAnnotations, ...this.userAnnotations].filter(a => !annotationState.isVisible(a));
    }

    get infoDotClasses(): string {
        const hiddenTypes = this.hiddenAnnotations.map(a => a.type);
        return [...new Set(hiddenTypes)].map(t => `dot-${t}`).join(" ");
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

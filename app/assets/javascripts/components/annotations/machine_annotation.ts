import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { annotationState } from "state/Annotations";


/**
 * This component represents a machine annotation.
 *
 * @element d-machine-annotation
 *
 * @prop {MachineAnnotationData} data - The machine annotation data.
 */
@customElement("d-machine-annotation")
export class MachineAnnotation extends ShadowlessLitElement {
    @property({ type: Object })
    data: MachineAnnotationData;

    protected get hasNotice(): boolean {
        return this.data.externalUrl !== null && this.data.externalUrl !== undefined;
    }

    protected get text(): string {
        // Filter out lines only containing dashes.
        return this.data.text.split("\n")
            .filter(s => !s.match("^--*$"))
            .join("\n");
    }

    render(): TemplateResult {
        return html`
            <div class="annotation machine-annotation ${this.data.type}"
                 @mouseenter="${() => annotationState.hoveredAnnotation = this.data}"
                 @mouseleave="${() => annotationState.hoveredAnnotation = null}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${I18n.t(`js.annotation.type.${this.data.type}`)}
                        ${this.hasNotice ? html`
                            <span>
                                ·
                                <a href="${this.data.externalUrl}" target="_blank">
                                    <i class="mdi mdi-information mdi-18 colored-info"
                                       title="${I18n.t("js.machine_annotation.external_url")}"
                                       data-bs-toggle="tooltip"
                                       data-bs-placement="top"
                                    ></i>
                                </a>
                            </span>
                        ` : ""}
                    </span>
                </div>
                <div class="annotation-text">${this.text}</div>
            </div>
        `;
    }
}

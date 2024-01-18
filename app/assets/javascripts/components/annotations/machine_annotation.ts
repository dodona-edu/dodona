import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { MachineAnnotation } from "state/MachineAnnotations";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";


/**
 * This component represents a machine annotation.
 *
 * @element d-machine-annotation
 *
 * @prop {MachineAnnotation} data - The machine annotation data.
 */
@customElement("d-machine-annotation")
export class MachineAnnotationComponent extends DodonaElement {
    @property({ type: Object })
    data: MachineAnnotation;

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
                 @mouseenter="${() => this.data.isHovered = true}"
                 @mouseleave="${() => this.data.isHovered = false}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${i18n.t(`js.annotation.type.${this.data.type}`)}
                        ${this.hasNotice ? html`
                            <span>
                                ·
                                <a href="${this.data.externalUrl}" target="_blank">
                                    <i class="mdi mdi-information mdi-18 colored-info"
                                       title="${i18n.t("js.machine_annotation.external_url")}"
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

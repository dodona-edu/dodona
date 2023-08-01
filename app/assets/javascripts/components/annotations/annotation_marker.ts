import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";
import {
    AnnotationData,
    annotationState,
    compareAnnotationOrders,
    isUserAnnotation
} from "state/Annotations";
import { MachineAnnotationData } from "state/MachineAnnotations";
/**
 * A marker that styles the slotted content based on the relevant annotations.
 * It applies a background color to user annotations and a wavy underline to machine annotations.
 *
 * @prop {AnnotationData[]} annotations The annotations to use for styling.
 *
 * @element d-annotation-marker
 */
@customElement("d-annotation-marker")
export class AnnotationMarker extends LitElement {
    @property({ type: Array })
    annotations: AnnotationData[];

    static colors = {
        "error": "var(--error-color, red)",
        "warning": "var(--warning-color, yellow)",
        "info": "var(--info-color, blue)",
        "annotation": "var(--annotation-color, green)",
        "question": "var(--question-color, orange)",
        "annotation-intense": "var(--annotation-intense-color, green)",
        "question-intense": "var(--question-intense-color, orange)",
    };

    static getStyle(annotation: AnnotationData): string {
        if (["error", "warning", "info"].includes(annotation.type)) {
            return `
                text-decoration: wavy underline ${AnnotationMarker.colors[annotation.type]} 1px;
                -webkit-text-decoration: wavy underline ${AnnotationMarker.colors[annotation.type]} 1px;
                text-decoration-skip-ink: none;
            `;
        } else {
            return `
                background: ${AnnotationMarker.colors[annotation.type]};
            `;
        }
    }

    get sortedAnnotations(): AnnotationData[] {
        return this.annotations.sort( compareAnnotationOrders );
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a)) as MachineAnnotationData | undefined;
        const size = 14;
        return firstMachineAnnotation && html`<svg style="position: absolute; top: ${16 - size/2}px; left: -${size/2}px" width="${size}" height="${size}" viewBox="0 0 24 24">
            <path fill="${AnnotationMarker.colors[firstMachineAnnotation.type]}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg>`;
    }

    get annotationStyles(): string {
        return this.sortedAnnotations.reverse().map(a => AnnotationMarker.getStyle(a)).join(" ");
    }

    render(): TemplateResult {
        return html`<style>
                :host {
                    position: relative;
                    ${this.annotationStyles}
                }
            </style><slot>${this.machineAnnotationMarkerSVG}</slot>`;
    }
}

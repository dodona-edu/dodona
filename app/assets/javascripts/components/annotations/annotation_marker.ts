import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";
import {
    Annotation,
    compareAnnotationOrders,
    isUserAnnotation
} from "state/Annotations";
import { MachineAnnotation } from "state/MachineAnnotations";
import { StateController } from "state/state_system/StateController";
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
    annotations: Annotation[];

    state = new StateController(this);

    static colors = {
        "error": "var(--error-color, red)",
        "warning": "var(--warning-color, yellow)",
        "info": "var(--info-color, blue)",
        "annotation": "var(--annotation-color, green)",
        "question": "var(--question-color, orange)",
        "annotation-intense": "var(--annotation-intense-color, green)",
        "question-intense": "var(--question-intense-color, orange)",
    };

    static getStyle(annotation: Annotation): string {
        if (["error", "warning", "info"].includes(annotation.type)) {
            // shorthand notation does not work in safari
            return `
                text-decoration-line: underline;
                text-decoration-color: ${AnnotationMarker.colors[annotation.type]};
                text-decoration-thickness: ${annotation.isHovered ? 2 : 1}px;
                text-decoration-style: wavy;
                text-decoration-skip-ink: none;
            `;
        } else {
            const key = annotation.isHovered ? `${annotation.type}-intense` : annotation.type;
            return `
                background: ${AnnotationMarker.colors[key]};
            `;
        }
    }

    /**
     * Returns the annotations sorted in order of importance.
     * Hovered annotations are prioritized over non-hovered annotations.
     * Otherwise the default order is used, defined in `compareAnnotationOrders`.
     *
     * Goal is to always show the style of the most important annotation.
     */
    get sortedAnnotations(): Annotation[] {
        return this.annotations.sort( (a, b) => {
            if (a.isHovered && !b.isHovered) {
                return -1;
            }

            if (b.isHovered && !a.isHovered) {
                return 1;
            }

            return compareAnnotationOrders(a, b);
        });
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a)) as MachineAnnotation | undefined;
        const size = firstMachineAnnotation?.isHovered ? 20 : 14;
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

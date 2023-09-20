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
            const strokeWidth = annotation.isHovered ? 1.7 : 0.7;
            // -webkit is required for chrome
            return `
                -webkit-mask-image: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="6" height="3">%3Cpath%20d%3D%22m0%202.5%20l2%20-1.5%20l1%200%20l2%201.5%20l1%200%22%20stroke%3D%22%23d12%22%20fill%3D%22none%22%20stroke-width%3D%22${strokeWidth}%22%2F%3E</svg>');
                mask-image: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="6" height="3">%3Cpath%20d%3D%22m0%202.5%20l2%20-1.5%20l1%200%20l2%201.5%20l1%200%22%20stroke%3D%22%23d12%22%20fill%3D%22none%22%20stroke-width%3D%22${strokeWidth}%22%2F%3E</svg>');
                -webkit-mask-position: left bottom;
                mask-position: left bottom;
                -webkit-mask-repeat: repeat-x;
                mask-repeat: repeat-x;
                background-color: ${AnnotationMarker.colors[annotation.type]};
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

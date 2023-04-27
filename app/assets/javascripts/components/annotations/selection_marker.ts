import { LitElement, html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { AnnotationMarker } from "components/annotations/annotation_marker";
import { annotationState } from "state/Annotations";

@customElement("d-selection-marker")
class SelectionMarker extends LitElement {
    render(): TemplateResult {
        return html`<style>
            :host {
                background: ${AnnotationMarker.colors[annotationState.isQuestionMode ? "question" : "annotation"]};
                padding-top: 3px;
                padding-bottom: 2px;
                margin-top: -3px;
                margin-bottom: -2px;
            }
        </style><slot></slot>`;
    }
}

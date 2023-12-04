import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, svg, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

/**
 * @element d-series-icon
 *
 * this icon visualizes the status of a series for a give user
 *
 * @cssprop --icon-color - the color of the icon
 * @cssprop --icon-background-color - the background color of the icon
 * @cssprop --deadline-icon-color - the color of the deadline icon
 * @cssprop --deadline-icon-background-color - the background color of the deadline icon
 *
 * @attr {string} deadline-class - a css class to apply related to the deadline if any
 * @attr {string} deadline-icon - the icon to show for the deadline if any
 * @attr {string} overlay-class - a css class to apply to the overlay if any
 * @attr {string} progress-class - a css class to apply that is related to the progress
 * @attr {string} progress-icon - the icon to show that indicates the progress, defaults to mdi-school
 * @attr {number} size - the size of the icon in pixels
 */
@customElement("d-series-icon")
export class SeriesIcon extends ShadowlessLitElement {
    @property({ type: String, attribute: "deadline-class" })
    deadline_class = "";
    @property({ type: String, attribute: "deadline-icon" })
    deadline_icon = "";
    @property({ type: String, attribute: "overlay-class" })
    overlay_class = "";
    @property({ type: String, attribute: "progress-class" })
    progress_class = "";
    @property({ type: String, attribute: "progress-icon" })
    progress_icon = "mdi-school";
    @property({ type: Number })
    size = 40;
    protected render(): TemplateResult {
        return html`
            <svg viewBox="0 0 40 40"
                 style="width: ${this.size}px; height: ${this.size}px; "
                 class="series-icon ${this.overlay_class}  ${this.progress_class}  ${this.deadline_class}"
            >
                <defs>
                    <linearGradient id="rainbow" gradientTransform="rotate(135, 0.5, 0.5)" >
                        <stop stop-color="var(--red)" offset="1%" />
                        <stop stop-color="var(--orange)" offset="25%" />
                        <stop stop-color="var(--yellow)" offset="40%" />
                        <stop stop-color="var(--green)" offset="60%" />
                        <stop stop-color="var(--blue)" offset="75%" />
                        <stop stop-color="var(--purple)" offset="99%" />
                    </linearGradient>
                </defs>

                <g class="icon-base" >
                    <circle cx="50%" cy="50%" r= "50%" fill="var(--icon-color)" class="outer-circle"></circle>
                    <circle cx="50%" cy="50%" r= "42%" fill="var(--icon-background-color)"></circle>
                    <foreignObject x="8" y="8"  height="24" width="24" style="color: var(--icon-color)">
                        <i class="mdi ${this.progress_icon}"></i>
                    </foreignObject>

                    ${this.deadline_icon ? svg`
                        <circle cx="33" cy="34.5" r= "11" fill="var(--deadline-icon-background-color)"></circle>
                        <foreignObject x="24" y="26"  height="18" width="18" style="color: var(--deadline-icon-color)">
                            <i class="mdi mdi-18 ${this.deadline_icon}"></i>
                        </foreignObject>
                    ` : ""}
                </g>

                ${this.overlay_class ? svg`
                    <foreignObject width="100%" height="100%" class="overlay">
                        <div></div>
                    </foreignObject>
                ` : ""}
            </svg>
        `;
    }
}

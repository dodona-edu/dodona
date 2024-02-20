import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, svg, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

export type SeriesProgressStatus = "not-yet-begun" | "started" | "completed" | "wrong";
export type SeriesDeadlineStatus = "met" | "missed" | null;
export type SeasonTheme = "christmas" | "december" | "valentine" | "mario-day" | "pi-day" | null;

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
 * @attr {string} deadline - The status of the deadline, if any
 * @attr {string} season - The season theme to apply, if any
 * @attr {string} progress - the progress of the user in the series
 * @attr {number} size - the size of the icon in pixels
 * @attr {string} status - the status of the series, displayed as a tooltip
 */
@customElement("d-series-icon")
export class SeriesIcon extends ShadowlessLitElement {
    @property({ type: String })
    progress: SeriesProgressStatus = "not-yet-begun";
    @property({ type: String })
    deadline: SeriesDeadlineStatus = null;
    @property({ type: String })
    season: SeasonTheme = null;
    @property({ type: Number })
    size = 40;
    @property({ type: String })
    status = "";

    static PROGRESS_ICONS: Record<SeriesProgressStatus, string> = {
        "not-yet-begun": "mdi-school",
        "started": "mdi-thumb-up",
        "completed": "mdi-check-bold",
        "wrong": "mdi-close",
    };

    static DEADLINE_ICONS: Record<SeriesDeadlineStatus, string> = {
        "met": "mdi-alarm-check",
        "missed": "mdi-alarm-off",
    };

    get progress_icon(): string {
        return SeriesIcon.PROGRESS_ICONS[this.progress];
    }

    get deadline_icon(): string {
        return SeriesIcon.DEADLINE_ICONS[this.deadline];
    }

    get deadline_class(): string {
        return this.deadline ? `deadline-${this.deadline}` : "";
    }

    protected render(): TemplateResult {
        return html`
            <svg viewBox="0 0 40 40"
                 style="width: ${this.size}px; height: ${this.size}px; "
                 class="series-icon ${this.season}  ${this.progress}  ${this.deadline_class}"
                 title="${this.status}"
                 data-bs-toggle="tooltip"
                 data-bs-placement="top"
            >
                ${ this.progress === "completed" && this.deadline !== "missed" ? svg`
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
                ` : ""}

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

                ${this.season ? svg`
                    <foreignObject width="100%" height="100%" class="overlay">
                        <div></div>
                    </foreignObject>
                ` : ""}
            </svg>
        `;
    }
}

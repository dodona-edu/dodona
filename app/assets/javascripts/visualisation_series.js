import { ViolinGraph } from "violin.ts";
import { StackedStatusGraph } from "stacked_status.ts";
import { TimeseriesGraph } from "timeseries.ts";
import { CTimeseriesGraph } from "cumulative_timeseries.ts";
import { Tooltip } from "bootstrap";

const graphFactory = {
    "violin": (url, containerId) => new ViolinGraph(url, containerId),
    "stacked": (url, containerId) => new StackedStatusGraph(url, containerId),
    "timeseries": (url, containerId) => new TimeseriesGraph(url, containerId),
    "ctimeseries": (url, containerId) => new CTimeseriesGraph(url, containerId),
};

/**
 * function to (de)activate graph mode (switch out ex list for graphs)
 * @param {HTMLElement} button Handle for toggle button
 * @param {string} seriesId The id of the series
 */
export function toggleStats(button, seriesId) {
    const card = document.getElementById(`series-card-${seriesId}`);
    card.classList.toggle("stats-active");
    if (card.classList.contains("stats-active")) {
        const tabs = card.querySelector(".stats-tab");
        setActiveToggle(
            tabs.querySelector(".violin"), "violin", seriesId, "#stats-container-", true);
        button.classList.replace("mdi-chart-line", "mdi-format-list-bulleted");
    } else {
        card.querySelector(".stats-container").innerHTML = "";
        button.classList.replace("mdi-format-list-bulleted", "mdi-chart-line");
    }
}

/**
 * function to switch active graph
 * @param {HTMLElement} activeNode the tab button that has been clicked
 * @param {string} title The title of the graph
 * @param {string} seriesId The id of the series
 * @param {string} selector The selector for the graph container (without id)
 * @param {boolean} init Boolean indicating no graph has been drawn yet
 */
export function setActiveToggle(activeNode, title, seriesId, selector, init=false) {
    // prevent active graph from being re-drawn except when it's the first time drawing it
    if (init || !activeNode.classList.contains("active")) {
        const card = document.getElementById(`series-card-${seriesId}`);
        const titleSpan = card.querySelector(".graph-title span");
        const info = card.querySelector(".graph-info");

        // init the graph
        graphFactory[title](seriesId, selector+seriesId).init();

        // set title
        titleSpan.textContent = I18n.t(`js.${title}_title`);

        // set all tab buttons to 'not active'
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.classList.remove("active");
        });
        // set current tab button as 'active'
        activeNode.classList.add("active");
        // update info description
        info.setAttribute("title", I18n.t(`js.${title}_desc`));
        // update tooltip content
        new Tooltip(info);
    }
}

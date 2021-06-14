import { ViolinGraph } from "violin.ts";
import { StackedStatusGraph } from "stacked_status.ts";
import { TimeseriesGraph } from "timeseries.ts";
import { CTimeseriesGraph } from "cumulative_timeseries.ts";
import { tooltip } from "util.js";

const graphFactory = {
    "violin": (url, containerId) => new ViolinGraph(url, containerId),
    "stacked": (url, containerId) => new StackedStatusGraph(url, containerId),
    "timeseries": (url, containerId) => new TimeseriesGraph(url, containerId),
    "ctimeseries": (url, containerId) => new CTimeseriesGraph(url, containerId),
};

// function to (de)activate graph mode (switch out ex list for graphs)
export function toggleStats(button, seriesId) {
    const card = document.getElementById(`series-card-${seriesId}`);
    const tabs = card.querySelector(".stats-tab");
    const content = card.querySelector(".series-content");
    const container = card.querySelector(".stats-container");
    const title = card.querySelector(".graph-title");
    const info = card.querySelector(".graph-info");
    if (getComputedStyle(tabs).display == "none") {
        tabs.style.display = "flex";
        info.style.display = "inline";
        title.style.display = "flex";
        container.style.display = "flex";
        content.style.display = "none";
        setActiveToggle(
            tabs.querySelector(".violin"), "violin", seriesId, "#stats-container-");
        button.className = button.className.replace("chart-line", "format-list-bulleted");
    } else {
        tabs.style.display = "none";
        info.style.display = "none";
        title.styledisplay = "none";
        container.html = "";
        container.style.display = "none";
        content.style.display = "block";
        button.className = button.className.replace("format-list-bulleted", "chart-line");
    }
}

// function to switch active graph
// returns true if the active tab switched
export function setActiveToggle(activeNode, title, seriesId, selector) {
    if (!activeNode.className.match(/^(.* )?active( .*)?$/)) {
        const card = document.getElementById(`series-card-${seriesId}`);
        const titleSpan = card.querySelector(".graph-title span");
        const info = card.querySelector(".graph-info");

        graphFactory[title](seriesId, selector+seriesId).init();
        titleSpan.textContent = I18n.t(`js.${title}_title`);
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.className = element.className.replace(" active", "");
        });
        info.onmouseover = () => info
            .setAttribute("data-original-title", I18n.t(`js.${title}_desc`));
        tooltip(info, I18n.t(`js.${title}_desc`));
        activeNode.className = activeNode.className + " active";
    }
}

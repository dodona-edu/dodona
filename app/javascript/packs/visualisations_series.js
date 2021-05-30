
import { ViolinGraph } from "violin.ts";
import { StackedStatusGraph } from "stacked_status.ts";
import { TimeseriesGraph } from "timeseries.ts";
import { CTimeseriesGraph } from "cumulative_timeseries.ts";
import { tooltip } from "util.js";

window.dodona.toggleStats = toggleStats;
window.dodona.setActiveToggle = setActiveToggle;

const graphFactory = {
    "violin": () => new ViolinGraph(),
    "stacked": () => new StackedStatusGraph(),
    "timeseries": () => new TimeseriesGraph(),
    "ctimeseries": () => new CTimeseriesGraph(),
};

// function to (de)activate graph mode (switch out ex list for graphs)
function toggleStats(button, seriesId) {
    const card = $(`#series-card-${seriesId}`);
    const tabs = card.find(".stats-tab");
    const content = card.find(".series-content");
    const container = card.find(".stats-container");
    const title = card.find(".graph-title");
    const info = card.find(".graph-info");
    if (tabs.css("display") == "none") {
        tabs.css("display", "flex");
        info.css("display", "inline");
        title.css("display", "flex");
        // info.css("display", "inline");
        container.css("display", "flex");
        content.css("display", "none");
        setActiveToggle(
            tabs.find(".violin").get()[0], "violin",
            seriesId, "/nl/stats/violin?series_id=", "#stats-container-"
        );
        button.className = button.className.replace("chart-line", "format-list-bulleted");
    } else {
        tabs.css("display", "none");
        info.css("display", "none");
        title.css("display", "none");
        console.log(container);
        container.html("");
        container.css("display", "none");
        content.css("display", "block");
        button.className = button.className.replace("format-list-bulleted", "chart-line");
    }
}

// function to switch active graph
// returns true if the active tab switched
function setActiveToggle(activeNode, title, seriesId, url, selector) {
    if (!activeNode.className.match(/^(.* )?active( .*)?$/)) {
        const card = $(`#series-card-${seriesId}`);
        const titleSpan = card.find(".graph-title span");
        const info = card.find(".graph-info");

        const graph = graphFactory[title]();
        graph.init(url+seriesId, selector+seriesId);

        titleSpan.html(I18n.t(`js.${title}_title`));
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.className = element.className.replace(" active", "");
        });
        info.on("mouseover", () => info
            .attr("data-original-title", I18n.t(`js.${title}_desc`)));
        tooltip(info, I18n.t(`js.${title}_desc`));
        activeNode.className = activeNode.className + " active";
    }
}

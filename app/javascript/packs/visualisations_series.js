
import { initViolin } from "violin.ts";
import { initStacked } from "stacked_status.ts";
import { initTimeseries } from "timeseries.ts";
import { initCumulativeTimeseries } from "cumulative_timeseries.ts";

window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;
window.dodona.initTimeseries = initTimeseries;
window.dodona.initCumulativeTimeseries = initCumulativeTimeseries;
window.dodona.toggleStats = toggleStats;
window.dodona.setActiveToggle = setActiveToggle;

function toggleStats(button, seriesId) {
    const card = $(`#series-card-${seriesId}`);
    const tabs = card.find(".stats-tab");
    const content = card.find(".series-content");
    const container = card.find(".stats-container");
    const title = card.find(".graph-title");
    const info = card.find(".graph-info");
    const height = content.height();
    if (tabs.css("display") == "none") {
        tabs.css("display", "flex");
        info.css("display", "inline");
        title.css("display", "flex");
        // info.css("display", "inline");
        container.css("display", "flex");
        content.css("display", "none");
        setActiveToggle(tabs.find(".violin").get()[0], "violin", seriesId);
        button.className = button.className.replace("chart-line", "format-list-bulleted");

        initViolin(
            `/nl/stats/violin?series_id=${seriesId}`,
            `#stats-container-${seriesId}`,
            height - tabs.get()[0].getBoundingClientRect().height - 5
        );
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

function setActiveToggle(activeNode, title, seriesId) { // returns true if the active tab switched
    if (!activeNode.className.match(/^(.* )?active( .*)?$/)) {
        const card = $(`#series-card-${seriesId}`);
        const titleSpan = card.find(".graph-title span");
        const info = card.find(".graph-info");

        titleSpan.html(I18n.t(`js.${title}_title`));
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.className = element.className.replace(" active", "");
        });
        info.on("mouseover", () => info
            .attr("data-original-title", I18n.t(`js.${title}_desc`))
            .tooltip("show"));
        activeNode.className = activeNode.className + " active";
        return true;
    }
    return false;
}

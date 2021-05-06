
import { initViolin } from "violin.ts";
import { initStacked } from "stacked_status.ts";
import { initTimeseries } from "timeseries.ts";
import { initCumulativeTimeseries } from "cumulative_timeseries.ts";
import { tooltip } from "util.js";

window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;
window.dodona.initTimeseries = initTimeseries;
window.dodona.initCumulativeTimeseries = initCumulativeTimeseries;
window.dodona.toggleStats = toggleStats;
window.dodona.setActiveToggle = setActiveToggle;

function toggleStats(button, seriesId) {
    const tabs = document.getElementById(`stats-tabs-${seriesId}`);
    const content = document.getElementById(`series-content-${seriesId}`);
    const container = document.getElementById(`stats-container-${seriesId}`);
    const title = document.getElementById(`graph-title-${seriesId}`);
    const info = document.getElementById(`graph-info-${seriesId}`);
    const height = content.clientHeight;
    if (tabs.style.display == "none") {
        tabs.style.display = "flex";
        title.style.display = "inline";
        info.style.display = "inline";
        container.style.display = "flex";
        content.style.display = "none";
        setActiveToggle(tabs.childNodes[1], "violin", seriesId);
        button.className = button.className.replace("chart-line", "format-list-bulleted");

        initViolin(
            `/nl/stats/violin?series_id=${seriesId}`,
            `#stats-container-${seriesId}`,
            height - tabs.clientHeight - 5
        );
    } else {
        tabs.style.display = "none";
        info.style.display = "none";
        title.style.display = "none";
        container.innerHTML = "";
        container.style.display = "none";
        content.style.display = "block";
        button.className = button.className.replace("format-list-bulleted", "chart-line");
    }
}

function setActiveToggle(activeNode, title, seriesId) { // returns true if the active tab switched
    if (!activeNode.className.match(/^(.* )?active( .*)?$/)) {
        const titleSpan = document.getElementById(`graph-title-${seriesId}`);
        const info = document.getElementById(`graph-info-${seriesId}`);

        titleSpan.innerHTML = I18n.t(`js.${title}_title`);
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.className = element.className.replace(" active", "");
        });
        info.onmouseover = () => $(info)
            .attr("data-original-title", I18n.t(`js.${title}_desc`))
            .tooltip("show");
        activeNode.className = activeNode.className + " active";
        return true;
    }
    return false;
}

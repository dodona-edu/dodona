
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
    const tabs = document.getElementById(`stats-tabs-${seriesId}`);
    const content = document.getElementById(`series-content-${seriesId}`);
    const container = document.getElementById(`stats-container-${seriesId}`);
    const height = content.clientHeight;
    if (tabs.style.display == "none") {
        tabs.style.display = "flex";
        container.style.display = "flex";
        content.style.display = "none";
        setActiveToggle(tabs.childNodes[1]);
        button.className = button.className.replace("chart-line", "format-list-bulleted");
        initViolin(
            `/nl/stats/violin?series_id=${seriesId}`,
            `#stats-container-${seriesId}`,
            height - tabs.clientHeight - 5
        );
    } else {
        tabs.style.display = "none";
        content.style.display = "block";
        container.innerHTML = "";
        container.style.display = "none";
        button.className = button.className.replace("format-list-bulleted", "chart-line");
    }
}

function setActiveToggle(activeNode) { // returns true if the active tab switched
    if (!activeNode.className.match(/^(.* )?active( .*)?$/)) {
        Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
            element.className = element.className.replace(" active", "");
        });
        activeNode.className = activeNode.className + " active";
        return true;
    }
    return false;
}

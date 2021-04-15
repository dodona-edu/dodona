
import { initViolin } from "violin.ts";
import { initStacked } from "stacked_status.ts";
import { initTimeseries } from "timeseries.ts";

window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;
window.dodona.initTimeseries = initTimeseries;
window.dodona.toggleStats = toggleStats;
window.dodona.setActiveToggle = setActiveToggle;

function toggleStats(seriesId) {
    const tabs = document.getElementById(`stats-tabs-${seriesId}`);
    if (tabs.style.display == "none") {
        tabs.style.display = "block";
        document.getElementById(`stats-button-${seriesId}`).textContent = "Hide statistics";
        initViolin(
            `/nl/stats/violin?series_id=${seriesId}`,
            `#stats-container-${seriesId}`
        );
    } else {
        tabs.style.display = "none";
        document.getElementById(`stats-container-${seriesId}`).innerHTML = "";
        document.getElementById(`stats-button-${seriesId}`).textContent = "Show statistics";
    }
}

function setActiveToggle(activeNode) {
    Array.from(activeNode.parentElement.getElementsByTagName("button")).forEach(element => {
        element.className = element.className.replace(" active", "");
    });
    activeNode.className = activeNode.className + " active";
}

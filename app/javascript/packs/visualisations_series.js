
import { initViolin } from "violin.ts";
import { initStacked } from "stacked_status.ts";
import { initTimeseries } from "timeseries.ts";

window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;
window.dodona.initTimeseries = initTimeseries;
window.dodona.toggleStats = toggleStats;

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

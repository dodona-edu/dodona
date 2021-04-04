import { initHeatmap } from "heatmap.ts";
import { initPunchcard } from "punchcard.js";
import { initViolin, vtest } from "violin.ts"
import { initStacked } from "stacked_status.ts"
import { initTimeseries } from "timeseries.ts"

window.dodona.initHeatmap = initHeatmap;
window.dodona.initPunchcard = initPunchcard;
window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;
window.dodona.initTimeseries = initTimeseries

// for figuring out input
window.dodona.vtest = vtest;

import { initHeatmap } from "heatmap.ts";
import { initPunchcard } from "punchcard.js";
import { initViolin, vtest } from "violin.ts"
import { initStacked } from "stacked_status.ts"

window.dodona.initHeatmap = initHeatmap;
window.dodona.initPunchcard = initPunchcard;
window.dodona.initViolin = initViolin;
window.dodona.initStacked = initStacked;    

// for figuring out input
window.dodona.vtest = vtest;

import { initHeatmap } from "heatmap.ts";
import { initPunchcard } from "punchcard.js";
import { testData, draw } from "visualisations/temp.ts";

window.dodona.initHeatmap = initHeatmap;
window.dodona.initPunchcard = initPunchcard;
draw(testData);

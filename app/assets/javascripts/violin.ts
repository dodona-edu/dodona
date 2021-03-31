import * as d3 from "d3";

function vtest() {
    console.log(d3.json('/nl/stats/violin?course_id=5&series_id=108'));
    console.log(d3.json('/nl/stats/stacked_status?course_id=5&series_id=108'))
}


export { vtest };
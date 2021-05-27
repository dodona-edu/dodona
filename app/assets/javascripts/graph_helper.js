import * as d3 from "d3";

/**
 * Breaks up y-axis labels into multiple lines when they get too long
 * @param {*} selection The selection of y-axis labels
 * @param {number} width     The width available to the labels
 * @param {[String, String]} exMap     An array of tuples [exId, exName] to link the two.
 */

function formatTitle(selection, width, exMap) {
    selection.each((datum, i, nodeList) => {
        const text = d3.select(nodeList[i]);    // select label i        
        
        // find exName corresponding to exId and split on space
        const words = exMap[datum].split(" ").reverse();
        let word = "";
        let line = [];
        let lineNumber = 0;
        const lineHeight = 1.1; // ems
        const y = text.attr("y"); // original y position (usually seems to be 'null')
        const dy = parseFloat(text.attr("dy")); // original y-shift
        let tspan = text.text(null)
            .append("tspan")    // similar to html span
            .attr("x", 0)
            .attr("y", y)
            .attr("dy", `${dy}em`);
        while (word = words.pop()) {
            line.push(word);
            tspan.text(line.join(" "));
            if (tspan.node().getComputedTextLength() > width) { // check if the line fits in the allowed width
                line.pop(); // if not remove last word
                tspan.text(line.join(" "));
                line = [word]; // start over with new line
                tspan = text.append("tspan") // create new tspan for new line
                    .attr("x", -0)
                    .attr("y", y)
                    .attr("dy", `${++lineNumber*lineHeight+dy}em`) // new line starts a little lower than last one
                    .text(word)
                    .attr("text-anchor", "end");
            }
        }
        const fontSize = parseInt(tspan.style("font-size"));
        const tSpans = text.selectAll("tspan");
        const breaks = tSpans.size(); // amount of times the name has been split
        // final y position adjustment so everything is centered
        tSpans.attr("y", -fontSize*(breaks-1)/2);
    });
}

export const d3Locale = {
    "dateTime": I18n.t("time.formats.default"),
    "date": I18n.t("date.formats.short"),
    "time": I18n.t("time.formats.short"),
    "periods": [I18n.t("time.am"), I18n.t("time.pm")],
    "days": I18n.t("date.day_names"),
    "shortDays": I18n.t("date.abbr_day_names"),
    "months": I18n.t("date.month_names").slice(1),
    "shortMonths": I18n.t("date.abbr_month_names").slice(1)
}

export { formatTitle };

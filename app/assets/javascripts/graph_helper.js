import * as d3 from "d3";

function formatTitle(selection, width, exMap) {
    selection.each((datum, i, nodeList) => {
        const text = d3.select(nodeList[i]);
        const words = exMap.find(ex => ex[0].toString()===datum.toString())[1].split(" ").reverse();
        let word = "";
        let line = [];
        let lineNumber = 0;
        const lineHeight = 1.1; // ems
        const y = text.attr("y");
        const dy = parseFloat(text.attr("dy"));
        let tspan = text.text(null)
            .append("tspan")
            .attr("x", 0)
            .attr("y", y)
            .attr("dy", `${dy}em`);
        while (word = words.pop()) {
            line.push(word);
            tspan.text(line.join(" "));
            if (tspan.node().getComputedTextLength() > width) {
                line.pop();
                tspan.text(line.join(" "));
                line = [word];
                tspan = text.append("tspan")
                    .attr("x", -0)
                    .attr("y", y)
                    .attr("dy", `${++lineNumber*lineHeight+dy}em`)
                    .text(word)
                    .attr("text-anchor", "end");
            }
        }
        const tSpans = text.selectAll("tspan");
        const breaks = tSpans.size();
        tSpans.attr("y", -5*(breaks-1)); // should change when changing font size
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

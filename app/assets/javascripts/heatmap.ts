import * as d3 from "d3";
import * as moment from "moment";

const selector = "#heatmap-container";
const margin = {top: 50, right: 10, bottom: 60, left: 30};
const isoDateFormat = "YYYY-MM-DD";

function firstDayOfAY(day: moment.Moment): moment.Moment {
    const prevYearStart = setToAYStart(day.clone().subtract(1, "year"));
    const currentYearStart = setToAYStart(day.clone());
    return day < currentYearStart ? prevYearStart : currentYearStart;
}

function setToAYStart(day: moment.Moment): moment.Moment {
    day.month(8).date(30);
    if (day.isoWeekday() >= 5) {
        day.isoWeekday(1);
    } else {
        day.subtract(1, "week").isoWeekday(1);
    }
    return day;
}

function initHeatmap(url: string, year: string | undefined) {
    d3.select(selector).attr("class", "text-center").append("span").text(I18n.t("js.loading"));
    d3.json(url).then(data => {
        d3.select(`${selector} *`).remove();

        let keys = Object.keys(data);

        if (year && year.match(/[0-9]{4}-[0-9]{4}/)) {
            const split = year.split("-");
            const firstDay = setToAYStart(moment.utc(`${split[0]}-01-01`)).format(isoDateFormat);
            const lastDay = setToAYStart(moment.utc(`${split[1]}-01-01`)).format(isoDateFormat);
            keys = keys.filter(k => {
                return k >= firstDay && k < lastDay;
            });
        }

        keys = keys.sort();

        const firstDay = firstDayOfAY(moment.utc(keys[0]));
        const lastDay = moment.min([
            firstDayOfAY(moment.utc(keys[keys.length - 1]).add(1, "year")),
            moment.utc(moment().format(isoDateFormat)).add(1, "day"),
        ]);

        for (let date = firstDay.clone(); date < lastDay; date.add(1, "day")) {
            if (!keys.includes(date.format(isoDateFormat))) {
                keys.push(date.format(isoDateFormat));
            }
        }

        drawHeatmap(keys.sort().map(k => (<[moment.Moment, number]>[moment.utc(k), data[k] || 0])));
    });
}

function drawHeatmap(data: Array<[moment.Moment, number]>) {
    const monthNames = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"].map(k => I18n.t(`js.months.${k}`));

    const container = d3.select(selector);
    const tooltip = container.append("div").attr("class", "d3-tooltip").style("opacity", 0);
    const width = (<Element>container.node()).getBoundingClientRect().width;
    const innerWidth = width - margin.left - margin.right;
    const chartBox = container.append("svg");
    const chart = chartBox.append("g")
        .attr("transform", `translate(${margin.left}, ${margin.top})`);

    const lastDay = data[data.length - 1][0];
    const firstAY = firstDayOfAY(data[0][0]);
    const lastAY = firstDayOfAY(lastDay);

    const years = lastAY.year() - firstAY.year() + 1;
    let maxWeeks = 0;
    const weekdaysData = [];
    const yearsData = [];
    for (let y = firstAY.clone(); y < setToAYStart(lastAY.clone().add(1, "year")); y = setToAYStart(y.add(1, "year"))) {
        const next = setToAYStart(y.clone().add(1, "year"));
        const weeks = moment.duration(next.diff(y)).asWeeks() + 1;
        if (weeks > maxWeeks) {
            maxWeeks = weeks;
        }
        weekdaysData.push(...[[weekdaysData.length / 4, "M"], [weekdaysData.length / 4, "W"], [weekdaysData.length / 4, "V"], [weekdaysData.length / 4, "Z"]]);
        yearsData.push(`${y.format("YYYY")}-${next.format("YYYY")}`);
    }

    const unitSize = Math.min(innerWidth / (maxWeeks), 50);
    const innerHeight = 7 * unitSize;
    const height = (innerHeight + margin.top + margin.bottom) * years;

    const max = Math.max(...data.map(d => d[1]));
    const colorRange = d3.scaleSequential(d3.interpolateBlues);
    colorRange.domain([1, max]);

    chartBox.attr("viewBox", `0,0,${width},${height}`);

    if (years > 1) {
        const yearsLabels = chart.selectAll("text.academic-year").data(yearsData);
        yearsLabels.enter().append("text").attr("class", "academic-year")
            .attr("x", innerWidth / 2 - 30)
            .attr("y", (d, i) => {
                return i * (innerHeight + margin.top + margin.bottom) - 30;
            })
            .text(d => d);
    }

    const weekdays = chart.selectAll(".week-day").data(weekdaysData);
    weekdays.enter().append("text").attr("class", "week-day")
        .attr("x", -14)
        .attr("y", (d, i) => {
            const graphOffset = ((i % 4) * 2 + 1) * unitSize - (unitSize - 10) / 2;
            const yearOffset = d[0] * (innerHeight + margin.top + margin.bottom);
            return graphOffset + yearOffset;
        })
        .text(d => d[1]);

    const firstMonth = firstAY.clone().add(1, "months").date(1);
    const lastMonth = lastDay.clone().date(1);
    const months = [firstMonth];
    const numMonths = moment.duration(lastMonth.diff(firstMonth)).asMonths() - 1;
    for (let i = 0; i < numMonths + 1; i++) {
        months.push(firstMonth.clone().add(i + 1, "months"));
    }

    const monthLabels = chart.selectAll(".month").data(months);
    monthLabels.enter()
        .append("text")
        .attr("class", "month")
        .style("opacity", 0)
        .text((d: moment.Moment) => monthNames[d.month()])
        .transition().duration(500)
        .style("opacity", 1)
        .attr("x", d => {
            const ayStart = firstDayOfAY(d);
            return moment.duration(d.clone().isoWeekday(1).diff(ayStart.clone().isoWeekday(1))).asWeeks() * unitSize + 1;
        })
        .attr("y", d => {
            const ayStart = firstDayOfAY(d);
            return (ayStart.year() - firstAY.year()) * (innerHeight + margin.top + margin.bottom) - 5;
        });

    const dayCells = chart.selectAll(".day-cell").data(data, d => d[0]);
    dayCells.enter().append("rect").attr("class", "day-cell")
        .attr("fill", "#fff")
        .on("mouseout", () => {
            tooltip.transition().duration(200).style("opacity", 0);
        })
        .on("mousemove", () => {
            tooltip
                .style("left", `${d3.mouse(chartBox.node())[0]}px`)
                .style("top", `${d3.mouse(chartBox.node())[1] - tooltip.node().getBoundingClientRect().height}px`);
        })
        .on("mouseover", d => {
            tooltip.transition().duration(200).style("opacity", .9);
            tooltip.html(`${d[0].format("DD")} ${monthNames[d[0].month()].toLowerCase()} ${d[0].format("YYYY")}: ${d[1]}`);
        })
        .transition().duration(500)
        .attr("width", unitSize - 2)
        .attr("height", unitSize - 2)
        .attr("fill", d => d[1] === 0 ? "#fbfbfb" : colorRange(d[1]))
        .attr("x", d => {
            const ayStart = firstDayOfAY(d[0]);
            return moment.duration(d[0].clone().isoWeekday(1).diff(ayStart.clone().isoWeekday(1))).asWeeks() * unitSize + 1;
        })
        .attr("y", d => {
            const ayStart = firstDayOfAY(d[0]);
            return (ayStart.year() - firstAY.year()) * (innerHeight + margin.top + margin.bottom) + (d[0].isoWeekday() - 1) * unitSize + 1;
        });
}

export {initHeatmap};

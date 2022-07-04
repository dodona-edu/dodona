/* eslint @typescript-eslint/no-use-before-define: "off" */

import * as d3 from "d3";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import minMax from "dayjs/plugin/minMax";
import duration from "dayjs/plugin/duration";
import isoWeek from "dayjs/plugin/isoWeek";
dayjs.extend(utc);
dayjs.extend(minMax);
dayjs.extend(duration);
dayjs.extend(isoWeek);

const selector = "#heatmap-container";
const margin = { top: 50, right: 10, bottom: 20, left: 30 };
const isoDateFormat = "YYYY-MM-DD";
const monthKeys = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
const dayKeys = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];

function firstDayOfAY(day: dayjs.Dayjs): dayjs.Dayjs {
    const prevYearStart = setToAYStart(day.subtract(1, "year"));
    const currentYearStart = setToAYStart(day);
    return day < currentYearStart ? prevYearStart : currentYearStart;
}

function setToAYStart(day: dayjs.Dayjs): dayjs.Dayjs {
    return day.month(8).date(1);
}

function initHeatmap(url: string, oldestFirst: boolean, year: string | undefined): void {
    d3.select(selector).attr("class", "text-center").append("span").text(I18n.t("js.loading"));
    const processor = function (data): void {
        if (data["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        const keys = Object.keys(data).sort();

        let firstDay;
        let lastDay;
        if (keys.length > 0) {
            firstDay = firstDayOfAY(dayjs.utc(keys[0]));
            lastDay = dayjs.min([
                firstDayOfAY(dayjs.utc(keys[keys.length - 1]).add(1, "year")),
                dayjs.utc(dayjs().format(isoDateFormat)).add(1, "day"),
            ]);
        } else {
            firstDay = firstDayOfAY(dayjs.utc(dayjs().format(isoDateFormat)));
            lastDay = dayjs.utc(dayjs().format(isoDateFormat)).add(1, "day");
        }

        for (let date = firstDay; date < lastDay; date = date.add(1, "day")) {
            if (!keys.includes(date.format(isoDateFormat))) {
                keys.push(date.format(isoDateFormat));
            }
        }
        drawHeatmap(
            keys
                .sort()
                .map(
                    k => [dayjs.utc(k), data[k] || 0] as [dayjs.Dayjs, number]
                ),
            oldestFirst,
            year
        );
    };
    d3.json(url).then(processor);
}

function drawHeatmap(data: [dayjs.Dayjs, number][], oldestFirst: boolean, year: string | undefined): void {
    const darkMode = window.dodona.darkMode;
    const emptyColor = darkMode ? "#303034" : "#fcfcff";
    const lowColor = darkMode ? "#4a4046" : "#ffd9df";
    const highColor = darkMode ? "#ffb2c0" : "#bc0049";

    const longMonthNames = monthKeys.map(k => I18n.t(`js.months.long.${k}`));
    const shortMonthNames = monthKeys.map(k => I18n.t(`js.months.short.${k}`));
    const weekdayNames = dayKeys.map(k => I18n.t(`js.weekdays.short.${k}`));

    const container = d3.select(selector);
    const tooltip = container.append("div").attr("class", "d3-tooltip").style("opacity", 0);
    const width = (container.node() as Element).getBoundingClientRect().width;
    const innerWidth = width - margin.left - margin.right;
    const chartBox = container.append("svg");
    const chart = chartBox.append("g")
        .attr("transform", `translate(${margin.left}, ${margin.top})`);

    const lastDay = data[data.length - 1][0];
    const firstAY = firstDayOfAY(data[0][0]);
    const lastAY = firstDayOfAY(lastDay);

    const years = lastAY.year() - firstAY.year() + 1;

    function yearOffset(i: number): number {
        if (oldestFirst) {
            return i * (innerHeight + margin.top + margin.bottom);
        }
        return (years - i - 1) * (innerHeight + margin.top + margin.bottom);
    }

    let maxWeeks = 0;
    const weekdaysData = [];
    const yearsData = [];
    for (
        let y = firstAY;
        y < setToAYStart(lastAY.add(1, "year"));
        y = setToAYStart(y.add(1, "year"))
    ) {
        const next = setToAYStart(y.add(1, "year"));
        const weeks = dayjs.duration(next.diff(y)).asWeeks() + 1;
        if (weeks > maxWeeks) {
            maxWeeks = weeks;
        }
        weekdaysData.push(
            ...[
                [weekdaysData.length / 3, weekdayNames[0]],
                [weekdaysData.length / 3, weekdayNames[2]],
                [weekdaysData.length / 3, weekdayNames[4]],
            ]
        );
        yearsData.push(`${y.format("YYYY")}–${next.format("YYYY")}`);
    }

    const unitSize = Math.min(innerWidth / (maxWeeks), 50);
    const weekendOffset = 2;
    const innerHeight = 7 * unitSize + weekendOffset;
    const height = (innerHeight + margin.top + margin.bottom) * years;

    const max = Math.max(...data.map(d => d[1]));
    const colorRange = d3.scaleSequential(d3.interpolate(lowColor, highColor)).domain([0, max]);

    chartBox.attr("viewBox", `0,0,${width},${height}`);

    const yearsLabels = chart.selectAll("text.academic-year").data(yearsData);
    yearsLabels.enter().append("text").attr("class", "academic-year")
        .attr("x", innerWidth / 2 - 30)
        .attr("y", (d, i) => {
            return yearOffset(i) - 30;
        })
        .attr("fill", "currentColor")
        .attr("font-weight", d => d === year && years > 1 ? "bold" : "normal")
        .text(d => d);

    const weekdays = chart.selectAll(".week-day").data(weekdaysData);
    weekdays.enter().append("text").attr("class", "week-day")
        .attr("x", -20)
        .attr("y", (d, i) => {
            const graphOffset = ((i % 3) * 2 + 1) * unitSize - (unitSize - 10) / 2;
            return graphOffset + yearOffset(d[0]);
        })
        .attr("fill", "currentColor")
        .text(d => d[1]);

    const firstMonth = firstAY.date(1);
    const lastMonth = lastDay.date(1);
    const months = [firstMonth];
    const numMonths = dayjs.duration(lastMonth.diff(firstMonth)).asMonths() - 1;
    for (let i = 0; i < numMonths + 1; i++) {
        months.push(firstMonth.add(i + 1, "months"));
    }

    const monthLabels = chart.selectAll(".month").data(months);
    monthLabels.enter()
        .append("text")
        .attr("class", "month")
        .attr("fill", "currentColor")
        .style("opacity", 0)
        .text((d: dayjs.Dayjs) => shortMonthNames[d.month()])
        .transition().duration(500)
        .style("opacity", 1)
        .attr("x", d => {
            const ayStart = firstDayOfAY(d);
            return dayjs.duration(d.isoWeekday(1).diff(ayStart.isoWeekday(1))).asWeeks() * unitSize + 1;
        })
        .attr("y", d => {
            const ayStart = firstDayOfAY(d);
            return yearOffset(ayStart.year() - firstAY.year()) - 5;
        });

    const dayCells = chart.selectAll(".day-cell").data(data, d => d[0]);
    dayCells.enter().append("rect").attr("class", "day-cell")
        .classed("empty", d => d[1] === 0)
        .attr("fill", emptyColor)
        .on("mouseout", () => {
            tooltip.transition().duration(200).style("opacity", 0);
        })
        .on("mousemove", event => {
            tooltip
                .style("left", `${d3.pointer(event, chartBox.node())[0] + 10}px`)
                .style("top", `${d3.pointer(event, chartBox.node())[1] - tooltip.node().getBoundingClientRect().height - 10}px`);
        })
        .on("mouseover", (event, d) => {
            tooltip.transition().duration(200).style("opacity", .9);
            tooltip.html(`${d[1]} ${I18n.t("js.submissions_on")} ${d[0].format("D")} ${longMonthNames[d[0].month()].toLowerCase()} ${d[0].format("YYYY")}`);
        })
        .transition().duration(500)
        .attr("width", unitSize - 2)
        .attr("height", unitSize - 2)
        .attr("x", d => {
            const ayStart = firstDayOfAY(d[0]);
            return dayjs.duration(d[0].isoWeekday(1).diff(ayStart.isoWeekday(1))).asWeeks() * unitSize + 1;
        })
        .attr("y", d => {
            const ayStart = firstDayOfAY(d[0]);
            return yearOffset(ayStart.year() - firstAY.year()) + (d[0].isoWeekday() - 1) * unitSize + 1 + (d[0].isoWeekday() > 5 ? weekendOffset : 0);
        })
        .transition().duration(500)
        .attr("fill", d => d[1] === 0 ? "" : colorRange(d[1]));
}

export { initHeatmap };

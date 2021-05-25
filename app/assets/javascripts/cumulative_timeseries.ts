import * as d3 from "d3";

let selector = "";
const margin = { top: 20, right: 50, bottom: 80, left: 40 };
let width = 0;
let height = 0;
const bisector = d3.bisector((d: Date) => d.getTime()).left;


function insertFakeData(data, maxCount): void {
    const end = new Date(d3.max(Object.values(data),
        records => d3.max(records)));
    const start = new Date(end);
    start.setDate(start.getDate() - 14);
    for (const exName of Object.keys(data)) {
        let count = 0;
        data[exName] = [];
        for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1 + Math.random()*2)) {
            const c = Math.round(Math.random()*5);
            if (count + c <= maxCount) {
                count += c;
                for (let i = 0; i < c; i++) {
                    data[exName].push(new Date(d));
                }
            }
        }
    }
}

function thresholdTime(n, min, max): () => Date[] {
    const ticks = d3.timeDay;
    return () => {
        return d3.scaleTime().domain([min, max]).ticks(ticks);
    };
}

function drawCumulativeTimeSeries(data, metaData, exMap): void {
    d3.timeFormatDefaultLocale({
        "dateTime": I18n.t("time.formats.default"),
        "date": I18n.t("date.formats.short"),
        "time": I18n.t("time.formats.short"),
        "periods": [I18n.t("time.am"), I18n.t("time.pm")],
        "days": I18n.t("date.day_names"),
        "shortDays": I18n.t("date.abbr_day_names"),
        "months": I18n.t("date.month_names").slice(1),
        "shortMonths": I18n.t("date.abbr_month_names").slice(1)
    });
    const exOrder: string[] = exMap.map(ex => ex[0]).reverse();
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const dateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));
    const dateArray = d3.timeDays(metaData["minDate"], metaData["maxDate"]);
    dateArray.unshift(metaData["minDate"]);
    let tooltipI = -1;

    const mapEx = (target: string): string =>
        exMap.find(ex => target.toString() === ex[0].toString());

    const svg = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height);

    // position graph
    const graph = svg
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // common y scale per exercise
    const y = d3.scaleLinear()
        .domain([0, 1])
        .range([innerHeight, 0]);

    // y axis
    graph.append("g")
        .call(d3.axisLeft(y).ticks(5).tickFormat((v: number) => `${100*v}%`));

    // Show the X scale
    const x = d3.scaleTime()
        .domain([metaData["minDate"], metaData["maxDate"]])
        .range([0, innerWidth]);

    // Color scale
    const color = d3.scaleOrdinal()
        .range(d3.schemeDark2)
        .domain(exOrder);

    let ticks = d3.timeDay.filter(d=>d3.timeDay.count(metaData["minDate"], d) % 2 === 0);
    let format = I18n.t("date.formats.weekday_short");
    if (metaData["dateRange"] > 20) {
        ticks = d3.timeMonth;
        format = "%B";
    }

    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${y(0)})`)
        .call(d3.axisBottom(x).ticks(ticks, format));

    const tooltip = graph.append("line")
        .attr("y1", 0)
        .attr("y2", innerHeight)
        .attr("pointer-events", "none")
        .attr("stroke", "currentColor")
        .style("width", 40);
    const tooltipLabel = graph.append("text")
        .text("_") // dummy text to calculate height
        .attr("text-anchor", "start")
        .attr("fill", "currentColor")
        .attr("font-size", "12px");
    tooltipLabel
        .attr("y", tooltipLabel.node().getBBox().height);
    const tooltipDots = graph.selectAll("dots")
        .data(Object.entries(data), d => d[0])
        .join("circle")
        .attr("r", 4)
        .style("fill", d => color(d[0]));
    const tooltipDotLabels = graph.selectAll("dotlabels")
        .data(Object.entries(data), d => d[0])
        .join("text")
        .attr("fill", d => color(d[0]))
        .attr("font-size", "12px");

    function tooltipNotFocused(): void {
        tooltipI = -1;
        const date = metaData["maxDate"];
        tooltip
            .attr("opacity", 0.6)
            .attr("x1", x(metaData["maxDate"]))
            .attr("x2", x(metaData["maxDate"]));
        tooltipLabel
            .attr("opacity", 0.6)
            .text(dateFormat(date))
            .attr(
                "x",
                x(date) - tooltipLabel.node().getBBox().width - 5 > 0 ?
                    x(date) - tooltipLabel.node().getBBox().width - 5 :
                    x(date) + 10
            );
        const last = dateArray.length-1;
        tooltipDots
            .attr("opacity", 0.6)
            .attr("cx", x(date))
            .attr("cy", d => y(d[1][last][1]/metaData["maxSum"]));
        tooltipDotLabels
            .attr("opacity", 0.6)
            .attr("text-anchor", "start")
            .text(
                d => `${Math.round(d[1][last][1]/metaData["maxSum"]*10000)/100}%`
            )
            .attr("x", x(date) + 5)
            .attr("y", d => y(d[1][last][1]/metaData["maxSum"])-5);
    }
    tooltipNotFocused();

    const legend = svg.append("g");


    let legendX = 0;
    for (const ex of exOrder) {
        // add legend colors dots
        const group = legend.append("g");

        group
            .append("rect")
            .attr("x", legendX)
            .attr("y", 0)
            .attr("width", 15)
            .attr("height", 15)
            .attr("fill", color(ex) as string);

        // add legend text
        group
            .append("text")
            .attr("x", legendX + 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(mapEx(ex)[1])
            .attr("fill", "currentColor")
            .style("font-size", "12px");

        legendX += group.node().getBBox().width + 20;
    }
    legend.attr(
        "transform",
        `translate(${width/2 - legend.node().getBBox().width/2},
        ${innerHeight+margin.top+margin.bottom/2})`
    );

    // add lines
    for (const exId of Object.keys(data)) {
        const exGroup = graph.append("g");
        const bins = data[exId];
        exGroup.selectAll("lines")
            .data([bins])
            .enter()
            .append("path")
            .attr("class", mapEx(exId))
            .style("stroke", color(exId) as string)
            .style("fill", "none")
            .attr("d", d3.line()
                .x(p => x(p[0]["x0"]))
                .y(p => y(p[1]/metaData["maxSum"]))
                .curve(d3.curveMonotoneX)
            );
    }

    function bisect(mx: number): {"date": Date; "i": number} {
        if (!dateArray) {
            return { "date": new Date(0), "i": 0 };
        }
        const date = x.invert(mx);
        const index = bisector(dateArray, date, 1);
        const a = index > 0 ? dateArray[index-1] : metaData["minDate"];
        const b = index < dateArray.length ? dateArray[index] : metaData["maxDate"];
        if (index < dateArray.length && date.getTime()-a.getTime() > b.getTime()-date.getTime()) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index-1 };
        }
    }

    svg.on("mousemove", e => {
        if (!dateArray) {
            return;
        }
        const { date, i } = bisect(d3.pointer(e, graph.node())[0]);
        if (i !== tooltipI) {
            tooltipI = i;
            tooltip
                .attr("opacity", 1)
                .attr("x1", x(date))
                .attr("x2", x(date));
            tooltipLabel
                .attr("opacity", 1)
                .text(dateFormat(date))
                .attr(
                    "x",
                    x(date) - tooltipLabel.node().getBBox().width - 5 > 0 ?
                        x(date) - tooltipLabel.node().getBBox().width - 5 :
                        x(date) + 10
                );
            // use line label width as reference for switch condition
            const doSwitch = x(date) + tooltipLabel.node().getBBox().width + 5 > innerWidth;
            tooltipDots
                .attr("opacity", 1)
                .attr("cx", x(date))
                .attr("cy", d => y(d[1][i][1]/metaData["maxSum"]));
            tooltipDotLabels
                .attr("opacity", 1)
                .text(
                    d => `${Math.round(d[1][i][1]/metaData["maxSum"]*10000)/100}% 
                    (${d[1][i][1]}/${metaData["maxSum"]})`
                )
                .attr("x", doSwitch ? x(date) - 5 : x(date) + 5)
                .attr("text-anchor", doSwitch ? "end" : "start")
                .attr("y", d => y(d[1][i][1]/metaData["maxSum"])-5);
        }
    });

    svg.on("mouseleave", () => {
        tooltipNotFocused();
    });
}

function initCumulativeTimeseries(url, containerId, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = (container.node() as HTMLElement).getBoundingClientRect().height - 5;
    }
    container
        .html("") // clean up possible previous visualisations
        .style("height", `${height}px`) // prevent shrinking after switching graphs
        .style("display", "flex")
        .style("align-items", "center")
        .append("div")
        .text(I18n.t("js.loading"))
        .style("margin", "auto");
    width = (container.node() as Element).getBoundingClientRect().width;
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }

        d3.select(`${selector} *`).remove();

        const data: {string: []} = raw.data;
        const metaData = {}; // used to store things needed to create scales
        if (Object.keys(data).length === 0) {
            container
                .style("height", "50px")
                .append("div")
                .text(I18n.t("js.no_data"))
                .style("margin", "auto");
            return;
        }

        height = 75 * Object.keys(raw.data).length;
        container.style("height", `${height}px`);
        Object.entries(data).forEach(entry => {
            data[entry[0]] = entry[1].map(d => new Date(d));
        });
        insertFakeData(data, raw.students);
        metaData["minDate"] = new Date(d3.min(Object.values(data),
            records => d3.min(records)));
        metaData["maxDate"] = new Date( // round maxDate to day
            d3.timeFormat("%Y-%m-%d")(d3.max(Object.values(data), records => d3.max(records)))
        );
        metaData["maxSum"] = raw.students ? raw.students : 0;
        metaData["dateRange"] = Math.round(
            (metaData["maxDate"].getTime() - metaData["minDate"].getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            let records = entry[1];
            // parse datestring to date
            records = records.map(r => new Date(r));

            const binned = d3.bin()
                .value(d => d.getTime())
                .thresholds(
                    thresholdTime(metaData["dateRange"]+1, metaData["minDate"], metaData["maxDate"])
                ).domain([metaData["minDate"], metaData["maxDate"]])(records);
            records = undefined; // records no longer needed
            data[exId] = d3.zip(binned, d3.cumsum(binned, d => d.length));
            metaData["maxSum"] = Math.max(data[exId][data[exId].length-1][1], metaData["maxSum"]);
        });

        drawCumulativeTimeSeries(data, metaData, raw.exercises);
    };
    d3.json(url)
        .then(processor);
}
export { initCumulativeTimeseries };

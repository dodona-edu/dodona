import * as d3 from "d3";
import { d3Locale } from "graph_helper.js";

export class CTimeseriesGraph {
    private selector: string;

    private readonly margin = { top: 20, right: 50, bottom: 80, left: 40 };
    private width: number; // svg width
    private height: number; // svg height
    private innerWidth: number; // graph width
    private innerHeight: number; // graph height

    private readonly bisector = d3.bisector((d: Date) => d.getTime()).left;
    private readonly longDateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));

    // private svg: d3.Selection<SVGSVGElement, unknown, HTMLElement, any>;
    private x: d3.ScaleTime<number, number>;
    private y: d3.ScaleLinear<number, number>;

    // tooltips things
    private tooltipIndex = -1; // used to prevent unnecessary tooltip updates
    private tooltipLine: d3.Selection<SVGLineElement, unknown, HTMLElement, any>;
    private tooltipLabel: d3.Selection<SVGTextElement, unknown, HTMLElement, any>;
    private tooltipDots: d3.Selection<
        Element | SVGCircleElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        any
    >;
    private tooltipDotLabels: d3.Selection<
        Element | SVGTextElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        any
    >;

    // data
    private data: Record<string, [d3.Bin<Date, Date>, number][]>;
    private maxSum: number;
    private exOrder: string[] // ordering of exercises
    private exMap: Record<string, string>;
    private dateRange: number; // difference between first and last date in days
    private dateArray: Date[];

    draw(): void {
        d3.timeFormatDefaultLocale(d3Locale);
        const minDate = this.dateArray[0];
        const maxDate = this.dateArray[this.dateArray.length - 1];

        const svg = d3.select(this.selector)
            .style("height", `${this.height}px`)
            .append("svg")
            .attr("width", this.width)
            .attr("height", this.height);

        // position graph
        const graph = svg
            .append("g")
            .attr("transform",
                "translate(" + this.margin.left + "," + this.margin.top + ")");

        // axis and scale settings
        // -----------------------------------------------------------------------------------------

        // common y scale per exercise
        this.y = d3.scaleLinear()
            .domain([0, 1])
            .range([this.innerHeight, 0]);

        // y axis
        graph.append("g")
            .call(d3.axisLeft(this.y).ticks(5).tickFormat((v: number) => `${100*v}%`));

        // Show the X scale
        this.x = d3.scaleTime()
            .domain([minDate, maxDate])
            .range([0, this.innerWidth]);

        // Color scale
        const color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.exOrder);

        let ticks = d3.timeDay.filter(d=>d3.timeDay.count(minDate, d) % 2 === 0);
        let format = I18n.t("date.formats.weekday_short");
        if (this.dateRange > 20) {
            ticks = d3.timeMonth;
            format = "%B";
        }

        // add x-axis
        graph.append("g")
            .attr("transform", `translate(0, ${this.y(0)})`)
            .call(d3.axisBottom(this.x).ticks(ticks, format));

        // -----------------------------------------------------------------------------------------

        // tooltip initialisation
        // -----------------------------------------------------------------------------------------
        const date = this.dateArray[this.dateArray.length-1];
        const last = this.dateArray.length-1;
        this.tooltipLine = graph.append("line")
            .attr("y1", 0)
            .attr("y2", this.innerHeight)
            .attr("x1", this.x(maxDate))
            .attr("x2", this.x(maxDate))
            .attr("pointer-events", "none")
            .attr("stroke", "currentColor")
            .style("width", 40)
            .attr("opacity", 0.6);
        this.tooltipLabel = graph.append("text")
            .text("_") // dummy text to calculate height
            .attr("text-anchor", "start")
            .attr("fill", "currentColor")
            .attr("font-size", "12px")
            .attr("opacity", 0.6)
            .text(this.longDateFormat(date));
        this.tooltipLabel
            .attr(
                "x",
                this.x(date) - this.tooltipLabel.node().getBBox().width - 5 > 0 ?
                    this.x(date) - this.tooltipLabel.node().getBBox().width - 5 :
                    this.x(date) + 10
            )
            .attr("y", this.tooltipLabel.node().getBBox().height);
        this.tooltipDots = graph.selectAll(".tooltipDot")
            .data(Object.entries(this.data), d => d[0])
            .join("circle")
            .attr("class", "tooltipDot")
            .attr("r", 4)
            .style("fill", d => color(d[0]))
            .attr("opacity", 0.6)
            .attr("cx", this.x(date))
            .attr("cy", d => this.y(d[1][last][1]/this.maxSum));
        this.tooltipDotLabels = graph.selectAll(".tooltipDotlabel")
            .data(Object.entries(this.data), d => d[0])
            .join("text")
            .attr("x", this.x(date) + 5)
            .attr("y", d => this.y(d[1][last][1]/this.maxSum)-5)
            .attr("class", "tooltipDotlabel")
            .attr("fill", d => color(d[0]))
            .attr("font-size", "12px")
            .attr("opacity", 0.6)
            .attr("text-anchor", "start")
            .text(
                d => `${Math.round(d[1][last][1]/this.maxSum*10000)/100}%`
            );
        // -----------------------------------------------------------------------------------------

        // Legend settings
        // -----------------------------------------------------------------------------------------
        const legend = svg.append("g");

        let legendX = 0;
        for (const ex of this.exOrder) {
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
                .text(this.exMap[ex])
                .attr("fill", "currentColor")
                .style("font-size", "12px");

            legendX += group.node().getBBox().width + 20;
        }
        legend.attr(
            "transform",
            `translate(${this.width/2 - legend.node().getBBox().width/2},
            ${this.innerHeight+this.margin.top+this.margin.bottom/2})`
        );
        // -----------------------------------------------------------------------------------------

        // add lines
        for (const exId of Object.keys(this.data)) {
            const exGroup = graph.append("g");
            const bins = this.data[exId];
            exGroup.selectAll("lines")
                .data([bins])
                .enter()
                .append("path")
                .style("stroke", color(exId) as string)
                .style("fill", "none")
                .attr("d", d3.line()
                    .x(p => this.x(p[0]["x0"]))
                    .y(this.innerHeight)
                    .curve(d3.curveMonotoneX)
                )
                .transition().duration(500)
                .attr("d", d3.line()
                    .x(p => this.x(p[0]["x0"]))
                    .y(p => this.y(p[1]/this.maxSum))
                    .curve(d3.curveMonotoneX)
                );
        }

        svg.on("mousemove", e => {
            if (!this.dateArray) {
                return;
            }
            const { date, i } = this.bisect(d3.pointer(e, graph.node())[0]);
            if (i !== this.tooltipIndex) {
                this.tooltipIndex = i;
                this.tooltipLine
                    .attr("opacity", 1)
                    .attr("x1", this.x(date))
                    .attr("x2", this.x(date));
                this.tooltipLabel
                    .attr("opacity", 1)
                    .text(this.longDateFormat(date))
                    .attr(
                        "x",
                        this.x(date) - this.tooltipLabel.node().getBBox().width - 5 > 0 ?
                            this.x(date) - this.tooltipLabel.node().getBBox().width - 5 :
                            this.x(date) + 10
                    );
                // use line label width as reference for switch condition
                const doSwitch = this.x(date)+this.tooltipLabel.node().getBBox().width+5 >
                    this.innerWidth;
                this.tooltipDots
                    .attr("opacity", 1)
                    .attr("cx", this.x(date))
                    .attr("cy", d => this.y(d[1][i][1]/this.maxSum));
                this.tooltipDotLabels
                    .attr("opacity", 1)
                    .text(
                        d => `${Math.round(d[1][i][1]/this.maxSum*10000)/100}% 
                        (${d[1][i][1]}/${this.maxSum})`
                    )
                    .attr("x", doSwitch ? this.x(date) - 5 : this.x(date) + 5)
                    .attr("text-anchor", doSwitch ? "end" : "start")
                    .attr("y", d => this.y(d[1][i][1]/this.maxSum)-5);
            }
        });

        svg.on("mouseleave", () => {
            this.tooltipNotFocused();
        });
    }

    drawNoData(): void {
        d3.select(this.selector)
            .style("height", "50px")
            .append("div")
            .text(I18n.t("js.no_data"))
            .style("margin", "auto");
    }

    prepareData(raw: Record<string, unknown>, url: string): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url)
                .then((r: Record<string, unknown>) => this.prepareData(r, url)), 1000);
            return;
        }
        // remove placeholder text
        d3.select(`${this.selector} *`).remove();

        const data = raw["data"] as Record<string, Date[]>;
        this.data = {};

        // No data
        if (Object.keys(data).length === 0) {
            this.drawNoData();
            return;
        }

        // extract id's and reverse order (since graphs are built bottom up)
        this.exOrder = (raw["exercises"] as [string, string][]).map(ex => ex[0]).reverse();

        // convert exercises into object to map id's to exercise names
        this.exMap = (raw["exercises"] as [string, string][])
            .reduce((map, [id, name]) => ({ ...map, [id]: name }), {});

        this.height = 75 * Object.keys(raw.data).length;

        Object.entries(data).forEach(entry => { // parse dates
            data[entry[0]] = entry[1].map(d => new Date(d));
        });

        const minDate = new Date(d3.min(Object.values(data),
            records => d3.min(records)));
        const maxDate = new Date( // round maxDate down to day
            d3.timeFormat("%Y-%m-%d")(d3.max(Object.values(data), records => d3.max(records)))
        );

        this.dateArray = d3.timeDays(minDate, maxDate);
        this.dateArray.unshift(minDate);

        this.maxSum = raw["students"] ? raw["students"] as number : 0; // max value
        this.dateRange = Math.round(
            (maxDate.getTime() - minDate.getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days
        Object.entries(data).forEach(([exId, records]) => {
            const binned = d3.bin()
                .value(d => d.getTime())
                .thresholds(
                    d3.scaleTime()
                        .domain([minDate.getTime(), maxDate.getTime()])
                        .ticks(d3.timeDay)
                ).domain([minDate.getTime(), maxDate.getTime()])(records);
            this.data[exId] = d3.zip(binned, d3.cumsum(binned, d => d.length));

            // if 'students' undefined calculate max value from data
            this.maxSum = Math.max(this.data[exId][this.data[exId].length-1][1], this.maxSum);
        });

        this.draw();
    }

    init(url: string, containerId: string, containerHeight: number): void {
        this.height = containerHeight;
        this.selector = containerId;
        const container = d3.select(this.selector);

        if (!this.height) {
            this.height = (container.node() as HTMLElement).getBoundingClientRect().height - 5;
        }
        container
            .html("") // clean up possible previous visualisations
            .style("height", `${this.height}px`) // prevent shrinking after switching graphs
            .style("display", "flex")
            .style("align-items", "center")
            .append("div")
            .text(I18n.t("js.loading"))
            .style("margin", "auto");
        this.width = (container.node() as Element).getBoundingClientRect().width;

        this.innerWidth = this.width - this.margin.left - this.margin.right;
        this.innerHeight = this.height - this.margin.top - this.margin.bottom;


        d3.json(url)
            .then((raw: Record<string, unknown>) => {
                this.prepareData(raw, url);
            });
    }

    // determine where to put tooltip line
    bisect(mx: number): {"date": Date; "i": number} {
        const min = this.dateArray[0];
        const max = this.dateArray[this.dateArray.length -1];
        if (!this.dateArray) {
            return { "date": new Date(0), "i": 0 };
        }
        const date = this.x.invert(mx);
        const index = this.bisector(this.dateArray, date, 1);
        const a = index > 0 ? this.dateArray[index-1] : min;
        const b = index < this.dateArray.length ? this.dateArray[index] : max;
        if (
            index < this.dateArray.length &&
            date.getTime()-a.getTime() > b.getTime()-date.getTime()
        ) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index-1 };
        }
    }

    // tooltip settings when mouse is not hovering over svg
    tooltipNotFocused(): void {
        this.tooltipIndex = -1;
        const date = this.dateArray[this.dateArray.length-1];
        const last = this.dateArray.length-1;
        this.tooltipLine
            .attr("opacity", 0.6)
            .attr("x1", this.x(date))
            .attr("x2", this.x(date));
        this.tooltipLabel
            .attr("opacity", 0.6)
            .text(this.longDateFormat(date))
            .attr(
                "x",
                this.x(date) - this.tooltipLabel.node().getBBox().width - 5 > 0 ?
                    this.x(date) - this.tooltipLabel.node().getBBox().width - 5 :
                    this.x(date) + 10
            );
        this.tooltipDots
            .attr("opacity", 0.6)
            .attr("cx", this.x(date))
            .attr("cy", d => this.y(d[1][last][1]/this.maxSum));
        this.tooltipDotLabels
            .attr("opacity", 0.6)
            .attr("text-anchor", "start")
            .text(
                d => `${Math.round(d[1][last][1]/this.maxSum*10000)/100}%`
            )
            .attr("x", this.x(date) + 5)
            .attr("y", d => this.y(d[1][last][1]/this.maxSum)-5);
    }
}

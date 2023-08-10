// eslint-disable-next-line
// @ts-nocheck
import * as d3 from "d3";
import { RawData } from "./series_graph";
import { SeriesExerciseGraph } from "./series_exercise_graph";
import { themeState } from "state/Theme";

export class TimeseriesGraph extends SeriesExerciseGraph {
    protected readonly baseUrl = "/stats/timeseries?series_id=";

    constructor(seriesId: string, containerId: string, data?: RawData) {
        super(seriesId, containerId, data);
        this.margin.right = 40;
    }

    private format: (d: Date) => string;

    // axes
    private x: d3.ScaleTime<number, number>;
    private color: d3.ScaleSequential<string>;

    // data
    private maxStack = 0; // largest value (max of colour scale domain)
    private minDate: Date;
    private maxDate: Date;
    private binTicks: Array<number>;
    private binStep: number;

    private data: {
        "ex_id": string,
        "ex_data": { date: Date; sum: number;[index: string]: number | Date }[]
    }[] = [];

    // svg elements
    private tooltip: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>;

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        if (this.binTicks.length < 2) {
            this.drawNoData();
            return;
        }

        super.draw(animation);

        const emptyColor = themeState.getCSSVariable("--d-off-surface");
        const highColor = themeState.getCSSVariable("--d-primary");
        const lowColor = d3.interpolateRgb(emptyColor, highColor)(0.2);

        const end = new Date(this.maxDate);
        end.setHours(0, 0, 0, 0); // bin and domain seem to handle end differently

        // Scales
        this.color = d3.scaleSequential(d3.interpolate(lowColor, highColor))
            .domain([0, this.maxStack]);
        this.x = d3.scaleBand()
            .domain(this.binTicks)
            .range([0, this.innerWidth]);

        // Axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.innerHeight - this.y.bandwidth() / 2})`)
            .call(
                d3.axisBottom(this.x)
                    .tickValues(this.binTicks.slice(0, this.binTicks.length-1))
                    .tickFormat(t => {
                        const asDate = new Date(t);
                        const timeZoneDiff = (asDate.getTimezoneOffset() - this.minDate.getTimezoneOffset()) / 60;
                        return this.binStep >= 24 ||
                            (
                                asDate.getHours() === (24 - timeZoneDiff) % 24 &&
                                asDate.getMinutes() === 0
                            ) ?
                            d3.timeFormat(I18n.t("date.formats.weekday_short"))(t):
                            d3.timeFormat(I18n.t("time.formats.plain_time"))(t);
                    })
            )
            .selectAll("text")
            .style("text-anchor", "end")
            .attr("dy", ".7em")
            .attr("transform", "rotate(-25)");

        this.graph.select(".domain").remove();

        // init tooltip
        this.tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // make sure cell size isn't bigger than bandwidth
        const rectSize = Math.min(
            this.y.bandwidth() * 1.5,
            this.innerWidth / this.binTicks.length - 5
        );
        // add cells
        this.graph.selectAll(".rectGroup")
            .data(this.data)
            .join("g")
            .attr("class", "rectGroup")
            // eslint-disable-next-line camelcase
            .each(({ ex_data, ex_id }, i, group) => {
                d3.select(group[i]).selectAll("rect")
                    .data(ex_data, d => d.date)
                    .join("rect")
                    .attr("class", "day-cell")
                    .classed("empty", d => d.sum === 0)
                    .attr("rx", 6)
                    .attr("ry", 6)
                    .attr("fill", emptyColor)
                    .attr("stroke", highColor)
                    .attr("x", d => this.x(d.date) + (this.x.bandwidth() - rectSize) / 2)
                    .attr("y", this.y(ex_id) + (this.y.bandwidth() - rectSize) / 2)
                    .on("mouseover", (_e, d) => this.tooltipHover(d))
                    .on("mousemove", e => this.tooltipMove(e))
                    .on("mouseout", () => this.tooltipOut())
                    .transition().duration(animation ? 500 : 0)
                    .attr("width", rectSize)
                    .attr("height", rectSize)
                    .attr("fill", d => d.sum === 0 ? "" : this.color(d.sum));
            });
        const divs = [60, 60, 24, 7];
        const units = ["sec", "min", "hour", "day", "week"];
        let step = this.binStep * 3600; // in seconds
        let i = 0;
        while (i < divs.length && step / divs[i] >= 1) {
            step /= divs[i];
            i++;
        }
        const legend = this.container
            .append("div")
            .style("position", "absolute")
            .style("top", `${this.innerHeight}px`)
            .append("div")
            .style("display", "flex")
            .style("align-items", "center");

        legend.append("div")
            .style("border-radius", "3.3px")
            .style("width", "20px")
            .style("height", "20px")
            .style("border-style", "solid")
            .style("border-width", "2px")
            .style("border-color", highColor);

        legend.append("span")
            .text(I18n.t(`time.units.${units[i]}`, { smart_count: step }))
            .attr("class", "legend-text")
            .style("margin-left", "5px");
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises, deadline }: RawData): void {
        // the type of one datum in the ex_data array
        type Datum = { date: (Date | string); status: string; count: number };

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data.forEach((d: Datum) => {
                d.date = new Date(d.date);
            });
        });

        let [minDate, maxDate] = d3.extent(
            data.flatMap(ex => ex.ex_data),
            (d: Datum) => d.date as Date
        );

        if (deadline) {
            maxDate = deadline;
        }

        this.minDate = this.dateStart ? new Date(this.dateStart) : new Date(minDate);
        this.maxDate = this.dateEnd ? new Date(this.dateEnd) : new Date(maxDate);

        // aim for 17 bins (between 15 and 20)
        const [binStep, binTicks, allignedStart] = this.findBinTime(this.minDate, this.maxDate, 17);
        this.binStep = binStep;
        this.binTicks = binTicks;
        this.minDate = allignedStart;
        this.maxDate = new Date(this.binTicks[this.binTicks.length-1]);

        if (this.binTicks.length < 2) {
            return;
        }

        if (!this.dateStart) {
            this.setPickerDates(this.minDate, this.maxDate);
        }

        this.data = [];
        this.maxStack = 0;
        // eslint-disable-next-line camelcase
        data.forEach(({ ex_id, ex_data }) => {
            let binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(binTicks)
                .domain([this.minDate.getTime(), this.maxDate.getTime()])(ex_data);

            if (binned[0].x0 < this.minDate.getTime()) {
                binned = binned.slice(1); // remove the 'before' bin
            }
            const binAmount = binned.length;
            // begin and end points of last bin are the same moment at times
            if (binned[binAmount-1].x0 === binned[binAmount-1].x1) {
                binned.pop();
            }

            const parsedData = [];
            // reduce bins to a single record per bin (see this.data)
            binned.forEach(bin => {
                const sum = d3.sum(bin, r => r["count"]);
                this.maxStack = Math.max(this.maxStack, sum);
                parsedData.push(bin.reduce((acc, r) => {
                    acc.sum = sum;
                    acc[r.status] += r.count;
                    return acc;
                }, this.statusOrder.reduce((acc, s) => {
                    acc[s] = 0; // make sure record is initialized with 0 counts
                    return acc;
                }, { "date": bin.x0, "sum": 0 })));
            });

            this.data.push({ ex_id: String(ex_id), ex_data: parsedData });
        });
    }

    /**
     * Shows date and number of submissions on mouse over
     *
     * @param {Object} d datum for a single rectangle
     */
    private tooltipHover(
        d: {
            [index: string]: number | Date;
            date: Date;
            sum: number;
        }): void {
        this.tooltip.transition()
            .duration(200)
            .style("opacity", .9);
        let message = "";
        if (this.binStep < 24) {
            const on = I18n.t("js.date_on");
            const timeFormat = d3.timeFormat(I18n.t("time.formats.plain_time"));
            const dateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));
            message = `
                <b>${timeFormat(d.date)} - ${timeFormat(new Date(d.date + this.binStep * 3600000))}</b>
                <br>${on} ${dateFormat(d.date)}:<br>
            `;
        } else if (this.binStep === 24) { // binning per day
            const format = d3.timeFormat(I18n.t("date.formats.weekday_long"));
            message = `${format(d.date)}:<br>`;
        } else if (this.binStep < 168) { // binning per multiple days
            const format = d3.timeFormat(I18n.t("date.formats.weekday_long"));
            message = `
                <b>${format(d.date)} - ${format(new Date(d.date - this.binStep * 3600000))}:</b>
                <br>
            `;
        } else { // binning per week(s)
            const weekDay = d3.timeFormat(I18n.t("date.formats.weekday_long"));
            const monthDay = d3.timeFormat(I18n.t("date.formats.monthday_long"));
            message = `
                <b>${weekDay(d.date)} - ${monthDay(new Date(d.date - this.binStep * 3600000))}:</b>
                <br>
            `;
        }
        const subString = d.sum === 1 ? I18n.t("js.submission") : I18n.t("js.submissions");
        message += `
            <b>${d.sum} ${subString}</b>
            `;
        this.statusOrder.forEach(status => {
            if (d[status]) {
                message += `
                <span style="display: flex; justify-items: center">
                ${this.submissionStatusIcon(status)}
                <b style="margin-right: 4px">${d[status]}</b>
                ${I18n.t(`js.status.${status.replaceAll(" ", "_")}`)}
                </span>`;
            }
        });
        this.tooltip.html(message);
    }

    /**
     * Update tooltip position on mouse move
     *
     * @param {*} e event parameter, used to determine mouse position
     */
    private tooltipMove(e: unknown): void {
        this.tooltip
            .style("left", `${d3.pointer(e, this.svg.node())[0] + 15}px`)
            .style("top", `${d3.pointer(e, this.svg.node())[1]}px`);
    }

    /**
     * Hide tooltip on mouse out
     */
    private tooltipOut(): void {
        this.tooltip.transition()
            .duration(500)
            .style("opacity", 0);
    }

    private submissionStatusIcon(status, size = 18): string {
        const [icon, color] = {
            "correct": ["check", "correct"],
            "wrong": ["close", "wrong"],
            "time limit exceeded": ["alarm", "wrong"],
            "runtime error": ["flash", "wrong"],
            "compilation error": ["flash-circle", "wrong"],
            "memory limit exceeded": ["memory", "wrong"],
            "output limit exceeded": ["script-text", "wrong"]
        }[status] || ["alert", "warning"];
        return `<i class="mdi mdi-${icon} mdi-${size} colored-${color}" style="margin-right: 5px"></i>`;
    }

    protected override init(draw = true, data = undefined): void {
        this.initTimePickers();
        super.init(draw, data);
    }
}

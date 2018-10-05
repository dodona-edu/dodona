let initPunchcard = function (url) {
    $.ajax({
        type: "GET",
        contentType: "application/json",
        url: url,
        dataType: "json",
        success: function (data) {
            drawPunchCard(data);
        },
        failure: function () {
            console.log("Failed to load submission data");
        },
    });
};

function formatData(data){
    let mapDates = data.map(s => {
        let d = new Date(s.created_at);
        return [d.getDay(), d.getHours()];
    });
    let dayHours = Array(7).fill().map(() => Array(24).fill(0));
    mapDates.forEach(d => dayHours[d[0]][d[1]] += 1);
    return dayHours;
}

function drawPunchCard(data) {
    const submissionData = formatData(data);
    console.log(submissionData);
}

export {initPunchcard};

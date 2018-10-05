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

function drawPunchCard(data) {
    console.log(data);
}

export {initPunchcard};

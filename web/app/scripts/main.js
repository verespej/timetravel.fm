$(document).ready(function () {

    $('.navbar').onePageNav({
        currentClass: 'active',
        changeHash: false,
        scrollSpeed: 300
    });

    var videoBG = $('#How .background-video').videoBG({
        mp4: "video/starfield.mp4",
        ogv: "video/starfield.ogv",
        webm: "video/starfield.webm",
        poster: "video/starfield_still.jpg"
    });



    var scrollAction = function (options) {
        _.extend(this, options);

        this.isActive = false;

        this.shouldTurnOn = function (windowPosition) {
            return windowPosition >= this.startPosition && windowPosition <= this.endPosition;
        };

        this.shouldTurnOff = function (windowPosition) {
            return windowPosition < this.startPosition || windowPosition > this.endPosition;
        };

        this.checkPosition = function (windowPosition) {
            if (!this.isActive && this.shouldTurnOn(windowPosition)) {
                this.turnOn();
            } else if (this.isActive && this.shouldTurnOff(windowPosition)) {
                this.turnOff();
            }
        };

        this.turnOn = function () {
            this.isActive = true;
            this.onZoneEnter();
        };

        this.turnOff = function () {
            this.isActive = false;
            this.onZoneExit();
        };
    };

    var videoPagePosition = $("#How").position().top;

    var videoBackgroundAction = new scrollAction({
        startPosition: videoPagePosition - 2.2*($(".page").height())/3,
        endPosition: videoPagePosition + ($(".page").height()) * 0.75,
        onZoneExit: function () {
            $("#How .background-video").addClass("transparent");
        },
        onZoneEnter: function () {
            console.log("you entered!");
            $("#How .background-video").removeClass("transparent");
        }

    });

    var imagePagePosition = $("#Why").position().top;

    var imageBackgroundPosition = new scrollAction({
        startPosition: imagePagePosition - 2.2*($(".page").height())/3,
        endPosition: imagePagePosition + ($(".page").height()) * 0.75,
        onZoneExit: function () {
            $("#Why .image-background").addClass("transparent");
        },
        onZoneEnter: function () {
            console.log("you entered!");
            $("#Why .image-background").removeClass("transparent");
        }

    });

    var revalidateZones = _.debounce(function () {
        var currentPosition = $(window).scrollTop();
        videoBackgroundAction.checkPosition(currentPosition);
        imageBackgroundPosition.checkPosition(currentPosition);
    }, 30);

    $(window).scroll(function (scrollEvent) {
        revalidateZones();

    });
});
$(document).ready(function () {

    $('.navbar').onePageNav({
        currentClass: 'active',
        changeHash: false,
        scrollSpeed: 300
    });

    var videoBG = $('#Page4 .video-background').videoBG({
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

    var videoPagePosition = $("#Page4").position().top;

    var videoBackgroundAction = new scrollAction({
        startPosition: videoPagePosition - 2*($("#Page4").height())/3,
        endPosition: videoPagePosition + ($("#Page4").height()) * 0.75,
        onZoneExit: function () {
            console.log("you exited!");
            $("#Page4 .video-background").addClass("transparent");
        },
        onZoneEnter: function () {
            console.log("you entered!");
            $("#Page4 .video-background").removeClass("transparent");
        }

    });

    var imagePagePosition = $("#Page2").position().top;

    var imageBackgroundPosition = new scrollAction({
        startPosition: imagePagePosition - 2.2*($("#Page2").height())/3,
        endPosition: imagePagePosition + ($("#Page2").height()) * 0.6,
        onZoneExit: function () {
            $("#Page2 .image-background").addClass("transparent");
        },
        onZoneEnter: function () {
            console.log("you entered!");
            $("#Page2 .image-background").removeClass("transparent");
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
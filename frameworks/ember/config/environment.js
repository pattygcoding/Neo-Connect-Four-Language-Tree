"use strict";

module.exports = function (environment) {
    const ENV = {
        modulePrefix: "connect-four-ember",
        environment,
        rootURL: "/",
        locationType: "history",
        EmberENV: {
            EXTEND_PROTOTYPES: false,
        },
    };

    if (environment === "production") {
        ENV.locationType = "hash";
    }

    return ENV;
};

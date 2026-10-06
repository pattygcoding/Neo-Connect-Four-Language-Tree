const fs = require("node:fs");
const path = require("node:path");

const Handlebars = require("handlebars");

const TEMPLATES = path.join(__dirname, "..", "templates");

function tone(value) {
    return value === "." ? "empty" : value.toLowerCase();
}

function createRenderer() {
    const env = Handlebars.create();

    env.registerPartial(
        "cell",
        fs.readFileSync(path.join(TEMPLATES, "partials", "cell.hbs"), "utf8"),
    );

    env.registerHelper("cellClass", (value) => `cell cell--${tone(value)}`);
    env.registerHelper("disabledAttr", (value) => (value ? "disabled" : ""));

    const template = env.compile(fs.readFileSync(path.join(TEMPLATES, "board.hbs"), "utf8"));
    return (view) => template(view);
}

module.exports = { createRenderer };

import { createApp } from "vue";
import App from "./App.vue";
import { configurePrism } from "./prism";
import { initSession } from "./store/session";
import { initTheme } from "./store/theme";
import "./styles/app.css";

// The 404.html shim parks a hop counter in sessionStorage so a junk path cannot
// redirect in circles.  Reaching the app means the trip worked, so clear it and
// leave the next bad link free to try again.
try {
    sessionStorage.removeItem("cf-404");
} catch {
    // private mode: the shim degrades to showing its own link
}

initTheme();
configurePrism();
initSession();

createApp(App).mount("#app");

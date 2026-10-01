import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import ConnectFour from "./ConnectFour";

createRoot(document.getElementById("root")).render(
    <StrictMode>
        <ConnectFour />
    </StrictMode>
);

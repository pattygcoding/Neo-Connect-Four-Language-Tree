import { bootstrapApplication } from "@angular/platform-browser";

import { ConnectFourComponent } from "./app/connect-four/connect-four.component";

bootstrapApplication(ConnectFourComponent).catch((error) => console.error(error));

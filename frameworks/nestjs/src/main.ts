import { NestFactory } from "@nestjs/core";
import * as session from "express-session";

import { AppModule } from "./app.module";

async function bootstrap(): Promise<void> {
    const app = await NestFactory.create(AppModule);
    app.use(
        session({
            secret: "change-me-in-production",
            resave: false,
            saveUninitialized: true,
        })
    );
    await app.listen(3000);
}

void bootstrap();

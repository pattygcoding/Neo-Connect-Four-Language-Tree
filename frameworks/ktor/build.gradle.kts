plugins {
    kotlin("jvm") version "2.0.0"
    id("io.ktor.plugin") version "2.3.12"
    application
}

application {
    mainClass.set("com.example.connectfour.ApplicationKt")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("io.ktor:ktor-server-core")
    implementation("io.ktor:ktor-server-netty")
    implementation("io.ktor:ktor-server-html-builder")
    implementation("io.ktor:ktor-server-sessions")
    implementation("ch.qos.logback:logback-classic:1.5.6")
}

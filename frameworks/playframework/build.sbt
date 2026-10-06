name := "connect-four-play"

version := "0.1.0"

lazy val root = (project in file("."))
    .enablePlugins(PlayScala)
    .settings(
        scalaVersion := "2.13.14",
        libraryDependencies += guice
    )

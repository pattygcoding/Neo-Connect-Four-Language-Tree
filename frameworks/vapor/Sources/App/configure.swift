import Vapor

func configure(_ app: Application) throws {
    app.middleware.use(app.sessions.middleware)
    try routes(app)
}
